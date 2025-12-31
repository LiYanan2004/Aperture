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
@dynamicMemberLookup
public final class Camera: SendableMetatype, Logging {
    /// A camera coordinator that consists of camera IO, session, rotation coordinator, etc.
    let coordinator: CameraCoordinator

    private var _cameraSwitchingTask: Task<Void, Error>?
    private var _automaticCameraObserver: AutomaticCameraObserver?
    /// The currently active capture video device.
    public var device: any SemanticCamera {
        willSet {
            _cameraSwitchingTask?.cancel()
            _cameraSwitchingTask = Task { @CameraActor in
                try await Task.sleep(for: .seconds(0.2))
                coordinator.cameraInputDevice = newValue.captureDevice
            }
        }
    }
    
    /// The active capture profile applied to the underlying `AVCaptureSession`.
    ///
    /// - note: Update this value would trigger a session re-configuration.
    public var profile: CameraCaptureProfile {
        willSet {
            Task { @CameraActor in
                coordinator.profile = newValue
            }
        }
    }
    
    /// An observable state of the camera.
    ///
    /// This value exposes session state, capture activity, orientation, and user-interaction related state that drives UI updates.
    ///
    /// `Camera` conforms to `@dynamicMemberLookup`, you can query value via ``subscript(dynamicMember:)-(KeyPath<State,T>)``, or update writable values via ``subscript(dynamicMember:)-(ReferenceWritableKeyPath<State,T>)``.
    internal var state: State
    
    /// Returns the value specified by the `keyPath` from the camera state object.
    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<State, T>) -> T {
        get { state[keyPath: keyPath] }
        set { state[keyPath: keyPath] = newValue }
    }
    /// Returns the value specified by the `keyPath` from the camera state object.
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }

    /// Create a camera instance with a specific device and profile.
    public init(
        device: any SemanticCamera,
        profile: CameraCaptureProfile
    ) {
        self.device = device
        self.profile = profile
        
        let coordinator = CameraCoordinator(configuration: profile)
        self.coordinator = coordinator
        defer {
            Task { @CameraActor in
                await MainActor.run {
                    self.coordinator.camera = self
                }
                coordinator.cameraInputDevice = device.captureDevice
            }
        }
        
        self.state = State(camera: nil)
        defer {
            Task { @MainActor in
                self.state.camera = self
            }
        }
        
        self._automaticCameraObserver = AutomaticCameraObserver(camera: self)
    }
    
    // MARK: - Session Management
    
    /// Starts the session.
    public func startRunning() async throws {
        guard await Camera.isAccessible else { throw CameraError.permissionDenied }
        guard self.captureSessionState == .idle else { throw CameraError.sessionAlreadStarted }
        
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
        self.captureSessionState = .idle
        state = State(camera: self)
        
        Task { @CameraActor in
            coordinator.captureSession.stopRunning()
        }
    }
    
    // MARK: - Internal Capture States
    
    internal var inFlightPhotoCaptureDelegates: [Int64: PhotoCaptureDelegate] = [:]
    
    // MARK: - Actions
    
    /// Sets the focus & exposure point of interest in the coordinate space of the capture device.
    ///
    /// - parameter pointOfInterest: The point of interest to focus & exposure
    /// - parameter focusMode: The focus mode of the capture device.
    /// - parameter exposureMode: The exposure mode of the capture device.
    @available(macOS, unavailable)
    public func setManualFocus(
        pointOfInterest: CGPoint,
        focusMode: AVCaptureDevice.FocusMode,
        exposureMode: AVCaptureDevice.ExposureMode
    ) {
        Task { @CameraActor in
            coordinator.withCurrentCaptureDevice { device in
                guard device.isFocusPointOfInterestSupported,
                      device.isExposurePointOfInterestSupported else {
                    self.logger.warning("Current device doesn't support focusing or exposing point of interst.")
                    return
                }
                device.focusPointOfInterest = pointOfInterest
                if device.isFocusModeSupported(focusMode) {
                    device.focusMode = focusMode
                }
                
                device.setExposureTargetBias(Float.zero)
                device.exposurePointOfInterest = pointOfInterest
                if device.isExposureModeSupported(exposureMode) {
                    device.exposureMode = exposureMode
                }
                
                let locked = focusMode == .locked || exposureMode == .locked
                // Enable `SubjectAreaChangeMonitoring` to reset focus at appropriate time
                device.isSubjectAreaChangeMonitoringEnabled = !locked
            }
        }
    }
}

// MARK: - Supplementary

extension Camera {
    /// A Boolean value indicates whether the video device is accessible.
    ///
    /// - Important: If user hasn't determines the permission, a privacy alert pops up.
    static public var isAccessible: Bool {
        get async {
            await AVCaptureDevice.requestAccess(for: .video)
        }
    }
}

// MARK: - Auxiliary

fileprivate extension Camera {
    final class AutomaticCameraObserver: NSObject {
        unowned let camera: Camera
        
        public init(camera: Camera) {
            self.camera = camera
            super.init()
            
            AVCaptureDevice.self.addObserver(
                self,
                forKeyPath: "systemPreferredCamera",
                options: [.new],
                context: nil
            )
            AVCaptureDevice.self.addObserver(
                self,
                forKeyPath: "userPreferredCamera",
                options: [.new],
                context: nil
            )
        }
        
        public override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            switch keyPath {
                case "systemPreferredCamera":
                    guard let automaticCamera = camera.device as? AutomaticCamera,
                          automaticCamera.preference == .systemPreferred
                    else { return }
                    Task { @CameraActor in
                        camera.coordinator.cameraInputDevice = (change?[.newKey] as? AVCaptureDevice) ?? BuiltInCamera().captureDevice
                    }
                case "userPreferredCamera":
                    guard let automaticCamera = camera.device as? AutomaticCamera,
                          automaticCamera.preference == .userPreferred
                    else { return }
                    Task { @CameraActor in
                        camera.coordinator.cameraInputDevice = (change?[.newKey] as? AVCaptureDevice) ?? BuiltInCamera().captureDevice
                    }
                default:
                    super.observeValue(
                        forKeyPath: keyPath,
                        of: object,
                        change: change,
                        context: context
                    )
            }
        }
    }
}
