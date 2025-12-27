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
    /// The currently active capture video device.
    public var device: any CameraDevice {
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
        device: any CameraDevice,
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
    
    @available(macOS, unavailable)
    func setManualFocus(
        pointOfInterst: CGPoint,
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
