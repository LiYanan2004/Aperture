//
//  CameraObject.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import Foundation
import AVFoundation
import OSLog
import Observation
import Combine

/// An observable camera instance camera feed, photo capturing, and more.
@Observable
public final class Camera: SendableMetatype, Logging {
    /// A camera coordinator that consists of camera IO, session, rotation coordinator, etc.
    let coordinator: CameraCoordinator

    /// Currently active capture device.
    private var _cameraSwitchingTask: Task<Void, Error>?
    public var device: any CameraDevice {
        willSet {
            _cameraSwitchingTask?.cancel()
            _cameraSwitchingTask = Task { @CameraActor in
                try await Task.sleep(for: .seconds(0.2))
                coordinator.cameraInputDevice = newValue.captureDevice
            }
        }
    }
    
    public var configuration: CameraConfiguration {
        willSet {
            Task { @CameraActor in
                coordinator.configuration = newValue
            }
        }
    }

    /// Create a camera instance with a specific device and configuration.
    public init(
        device: any CameraDevice,
        configuration: CameraConfiguration
    ) {
        self.device = device
        self.configuration = configuration
        
        let coordinator = CameraCoordinator(configuration: configuration)
        self.coordinator = coordinator
        
        Task { @CameraActor in
            await MainActor.run {
                self.coordinator.camera = self
            }
            coordinator.cameraInputDevice = device.captureDevice
        }
    }
    
    // MARK: - Session Management

    /// A obvserable value indicates the current state of the session.
    public var captureSessionState: CaptureSessionState = .idle
    public enum CaptureSessionState {
        case idle
        case running
        case configuring
    }
    
    /// Starts the session.
    public func startRunning() async throws {
        guard await Camera.isAccessible else { throw CameraError.permissionDenied }
        guard captureSessionState != .running else { throw CameraError.sessionAlreadStarted }

        Task { @CameraActor in
            try coordinator.configureSession()
            if !coordinator.captureSession.isRunning {
                coordinator.captureSession.startRunning()
            }
            
            if coordinator.captureSession.isRunning {
                Task { @MainActor in
                    self.captureSessionState = .running
                }
            }
        }
    }
    
    /// Stops the session.
    public func stopRunning() {
        Task { @CameraActor in
            coordinator.captureSession.stopRunning()
            if coordinator.captureSession.isRunning == false {
                self.captureSessionState = .idle
            }
        }
    }
    
    // MARK: - Camera State

    /// An observable angle to apply to the preview layer so that it’s level relative to gravity.
    ///
    /// You can use this value to rotate the UI of camera controls if you does not support certain orientation (for example: portrait mode only).
    internal(set) public var previewRotationAngle: CGFloat = 0
    /// An observable angle to apply to photos or videos it captures with the device so that they’re level relative to gravity.
    internal(set) public var captureRotationAngle: CGFloat = 0
    
    /// An observable boolean value indicates whether the preview layer is dimming.
    internal(set) public var previewDimming = false
    /// An observable boolean value indicates whether the system is busy processing captured photo.
    internal(set) public var isBusyProcessing = false
    /// An observable boolean value indicates whether the shutter is disabled for some reason.
    internal(set) public var shutterDisabled = false
    
    /// Requested photo capture options.
    ///
    /// > Tip:
    /// > You can update this value via ``setPhotoCaptureOptions(_:)``.
    /// >
    /// > Note that updating this vlaue after running the session will trigger a session re-configuration if the option updates.
    ///
    /// - SeeAlso: ``setPhotoCaptureOptions(_:)``
    internal(set) public var photoCaptureOptions: RequestedPhotoCaptureOptions = []
    /// An observable integer value indicates how many live photo capturing is in progress.
    internal(set) public var inProgressLivePhotoCount = 0
    
    /// An observable value indicates flash state of current capture device for the capturing.
    public var flash = CameraFlash(
        deviceEligible: false, // this will be updated during session setup
        userSelectedMode: .off,
        isFlashRecommendedByScene: false
    )
    
    /// An observable boolean value indicates whether the focus is locked by user (via long press).
    ///
    /// - SeeAlso: ``CameraViewFinder``
    internal(set) public var focusLocked = false
    #if os(iOS)
    /// A value that controls the cropping and enlargement of images captured by the device.
    public var zoomFactor: CGFloat = 1.0 {
        willSet {
            guard newValue != self.zoomFactor else { return }
            
            coordinator.withCurrentCaptureDevice { device in
                device.videoZoomFactor = newValue
            }
        }
    }
    /// The zoom factor of the base camera (typically the wide-angle / “1x” camera).
    ///
    /// - SeeAlso: ``displayZoomFactor``
    internal(set) public var baseZoomFactor: CGFloat = 1.0
    /// A zoom factor normalized for on-screen presentation.
    ///
    /// This value represents the effective zoom relative to the base (wide-angle) camera, making it suitable for display in the user interface.
    public var displayZoomFactor: CGFloat {
        zoomFactor / baseZoomFactor
    }
    #endif
    
    @available(macOS, unavailable)
    func setManualFocus(
        pointOfInterst: CGPoint,
        focusMode: AVCaptureDevice.FocusMode,
        exposureMode: AVCaptureDevice.ExposureMode
    ) {
        coordinator.withCurrentCaptureDevice { device in
            guard device.isFocusPointOfInterestSupported,
                  device.isExposurePointOfInterestSupported else {
                self.logger.warning("Current device doesn't support focusing or exposing point of interst.")
                return
            }
            device.focusPointOfInterest = pointOfInterst
            if device.isFocusModeSupported(focusMode) {
                device.focusMode = focusMode
            }
            
            device.setExposureTargetBias(Float.zero)
            device.exposurePointOfInterest = pointOfInterst
            if device.isExposureModeSupported(exposureMode) {
                device.exposureMode = exposureMode
            }
            
            let locked = focusMode == .locked || exposureMode == .locked
            // Enable `SubjectAreaChangeMonitoring` to reset focus at appropriate time
            device.isSubjectAreaChangeMonitoringEnabled = !locked
        }
    }
    
    // MARK: - Internal Capture States
    
    private var inFlightPhotoCaptureDelegates: [Int64: PhotoCaptureDelegate] = [:]
}

// MARK: - Photo Capture

extension Camera {
    /// Takes a photo of current scene.
    nonisolated public func takePhoto(configuration: PhotoCaptureConfiguration) async throws -> CapturedPhoto {
        let context = await coordinator.outputContext(for: PhotoCaptureService.self)
        guard let context else { throw CaptureError.noContext }
        
        let photoOutput = await coordinator.activeOutputs.first(byUnwrapping: { $0 as? AVCapturePhotoOutput })
        let service = self.configuration.photoCaptureService
        guard let photoOutput, let service else { throw CaptureError.photoOutputServiceNotAvailable }
        
        let photoSettings = try await service.photoSettings(
            output: photoOutput,
            configuration: configuration,
            context: context
        )
        let capturedPhoto = try await withPhotoOutputReadinessCoordinatorTracking(
            output: photoOutput,
            photoSettings: photoSettings
        ) {
            try await withCheckedThrowingContinuation { continuation in
                let delegate = PhotoCaptureDelegate(
                    camera: self,
                    continuation: continuation
                )
                inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = delegate

                photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
            }
        }
        
        inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = nil
        
        return capturedPhoto
    }
    
    private func withPhotoOutputReadinessCoordinatorTracking<T>(
        output: AVCapturePhotoOutput,
        photoSettings: AVCapturePhotoSettings,
        perform action: () async throws -> T
    ) async rethrows -> T {
        var readinessCoordinator: AVCapturePhotoOutputReadinessCoordinator?
        #if os(iOS)
        readinessCoordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: output)
        
        let delegate = PhotoReadinessCoordinatorDelegate(camera: self)
        defer { _ = delegate }
        readinessCoordinator?.delegate = delegate
        #endif
        
        readinessCoordinator?.startTrackingCaptureRequest(using: photoSettings)
        defer { readinessCoordinator?.stopTrackingCaptureRequest(using: photoSettings.uniqueID) }
        return try await action()
    }
}

// MARK: - Supplementary

extension Camera {
    static var isAccessible: Bool {
        get async {
            await AVCaptureDevice.requestAccess(for: .video)
        }
    }
}
