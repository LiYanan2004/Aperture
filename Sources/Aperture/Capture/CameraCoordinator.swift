//
//  CameraCoordinator.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import AVFoundation
import Foundation
import Combine

/// A camera coordinator responsible for managing shared camera infrastructure, including capture session, device input, capture output and more.
@CameraActor
final class CameraCoordinator: NSObject, Logging {
    /// The ``Camera`` instance.
    @MainActor weak var camera: Camera?
    /// The capture preview.
    nonisolated let cameraPreview = CameraPreview()
    
    nonisolated internal init(configuration: CameraConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    /// The aspect ratio (width / height) of the currently selected video format.
    private var cameraAspectRatio: CGFloat {
        guard let cameraInputDevice else { return 1.0 }
        
        let formatDescription = cameraInputDevice.activeFormat.formatDescription
        let dims = CMVideoFormatDescriptionGetDimensions(formatDescription)
        return CGFloat(dims.width) / CGFloat(dims.height)
    }
    
    // MARK: - Session
    
    /// The capture session.
    internal let captureSession = AVCaptureSession()
    /// The configuration of the camera.
    internal var configuration: CameraConfiguration {
        didSet {
            Task { @CameraActor in
                try await configureSession()
            }
        }
    }
    
    /// Configure current session and corresponding capture pipeline with current configuration and devices.
    internal func configureSession() async throws {
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        
        if captureSession.canSetSessionPreset(configuration.sessionPreset) {
            captureSession.sessionPreset = configuration.sessionPreset
        }
        
        // Removes existing input
        if let cameraInput {
            captureSession.removeInput(cameraInput)
        }
        
        // Adds new input
        guard let inputDevice = cameraInputDevice else { throw CameraError.invalidCaptureDevice }
        self.cameraInput = try addInput(from: inputDevice)
        
        // Remove existing output to re-configure.
        self.outputs.forEach {
            captureSession.removeOutput($0.output)
        }
        
        // Add new outputs
        let camera = await camera
        let outputs: [any CaptureOutput] = if configuration.sessionPreset == .photo {
            [photoOutput]
        } else {
            [photoOutput, videoOutput]
        }
        
        for output in outputs {
            addOutput(output.output)
            if let camera {
                try output.updateOutput(camera)
            }
        }
        
        // Connect to the preview
        cameraPreview.connect(to: captureSession)
        
        // Setup rotation coordinator for adaptive UI and capture content rotation.
        rotationCoordinator = await MainActor.run {
            AVCaptureDevice.RotationCoordinator(
                device: inputDevice,
                previewLayer: cameraPreview.layer
            )
        }
        observeRotationCoordinator()
    }

    // MARK: - Input
    
    /// The camera device input which has been successfully added to the session.
    private var cameraInput: AVCaptureDeviceInput?
    /// The camera input device that has been successfully added to the session.
    var cameraInputDevice: AVCaptureDevice? {
        didSet {
            Task { @CameraActor in
                try await configureSession()
            }
        }
    }
    
    /// Makes device input from the capture device and add it to the pipeline if possible.
    @discardableResult
    private func addInput(from inputDevice: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let deviceInput = try AVCaptureDeviceInput(device: inputDevice)
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        return deviceInput
    }
    
    // MARK: - Output
    
    /// A video output for movie capturing.
    nonisolated public let videoOutput = MovieCapture()
    /// A photo output for photo capturing.
    nonisolated public let photoOutput = PhotoCapture()
    /// A set of currently active capture outputs.
    public var outputs: [any CaptureOutput] = []
    
    /// Adds the capture output to the pipeline if possible.
    private func addOutput(_ output: AVCaptureOutput) {
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
    }
    
    // MARK: - Rotation Coordinator
    
    /// A set of observers that observe the properties of `rotationCoordinator`.
    nonisolated(unsafe) private var rotationObservers: Set<AnyCancellable> = []
    /// A rotation coordinator that monitors physical orientation to ensure the level of preview and captured content is relative to gravity.
    nonisolated(unsafe) private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    
    private func observeRotationCoordinator() {
        guard let rotationCoordinator else { return }
        rotationObservers.removeAll()
        
        withValueObservation(
            of: rotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelCapture,
            cancellables: &rotationObservers
        ) { [weak self] angle in
            self?.outputs.forEach({ $0.setVideoRotationAngle(angle) })
            Task { @MainActor in
                self?.camera?.captureRotationAngle = angle
            }
        }
        
        withValueObservation(
            of: rotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelPreview,
            cancellables: &rotationObservers
        ) { [weak self] angle in
            Task { @MainActor in
                self?.camera?.previewRotationAngle = angle
            }
        }
    }
    
    #if os(iOS)
    func setManualFocus(
        pointOfInterst: CGPoint,
        focusMode: AVCaptureDevice.FocusMode,
        exposureMode: AVCaptureDevice.ExposureMode
    ) {
        withCurrentCaptureDevice { device in
            guard device.isFocusPointOfInterestSupported,
                  device.isExposurePointOfInterestSupported else {
                logger.warning("Current device doesn't support focusing or exposing point of interst.")
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
    #endif
    
    public func withCurrentCaptureDevice(
        perform action: @CameraActor (AVCaptureDevice) throws -> Void
    ) {
        guard let cameraInputDevice else { return }
        do {
            try cameraInputDevice.lockForConfiguration()
            defer { cameraInputDevice.unlockForConfiguration() }
            
            try action(cameraInputDevice)
        } catch {
            logger.error("Cannot lock device for configuration: \(error.localizedDescription)")
        }
    }
}
