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
public final class Camera: SendableMetatype {
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

    /// Create a camera instance with a specific device and configuration.
    public init(
        device: any CameraDevice,
        configuration: CameraConfiguration
    ) {
        self.device = device
        
        let coordinator = CameraCoordinator(configuration: configuration)
        self.coordinator = coordinator
        
        Task { @CameraActor in
            coordinator.cameraInputDevice = device.captureDevice
        }
        
        Task { @MainActor in
            self.coordinator.camera = self
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
            try await coordinator.configureSession()
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
    /// An observable integer value indicates how many live photo capturing is in progress.
    internal(set) public var inProgressLivePhoto = 0
    
    /// Requested photo capture options.
    ///
    /// > Tip:
    /// > You can update this value via ``setPhotoCaptureOptions(_:)``.
    /// >
    /// > Note that updating this vlaue after running the session will trigger a session re-configuration if the option updates.
    ///
    /// - SeeAlso: ``setPhotoCaptureOptions(_:)``
    internal(set) public var photoCaptureOptions: RequestedPhotoCaptureOptions = []
    
    /// An observable value indicates current flash mode for capturing.
    public var flashMode: AVCaptureDevice.FlashMode = .off
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
}

// MARK: - Camera Actions

extension Camera {
    /// Takes a photo of current scene.
    nonisolated public func takePhoto(configuration: PhotoCaptureConfiguration) async throws -> CapturedPhoto {
        try await coordinator.photoOutput.takePhoto(from: self, configuration: configuration)
    }
    
    nonisolated private func recordVideo(configuration: MovieCaptureConfiguration) async throws {
        fatalError("Unimplemented")
    }
}

// MARK: - Option Updates

extension Camera {
    
    /// Adjust capture pipeline to fit the requested capture options if the device statisfy the requirements.
    ///
    /// - note: Updating this vlaue after running the session will trigger a session re-configuration if the option updates.
    /// - SeeAlso: ``photoCaptureOptions``
    nonisolated public func setPhotoCaptureOptions(
        _ options: RequestedPhotoCaptureOptions
    ) {
        photoCaptureOptions = options
        Task { @CameraActor in
            guard coordinator.photoOutput.captureOptions != options else { return }
            coordinator.photoOutput.captureOptions = options
            
            if captureSessionState != .idle {
                try await coordinator.configureSession()
            }
        }
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
