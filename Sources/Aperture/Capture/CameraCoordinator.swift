//
//  CameraCoordinator.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import AVFoundation
import Foundation
import Combine
import SwiftUI

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
        setConfigurationState(true)
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
            setConfigurationState(false)
        }
        
        if captureSession.canSetSessionPreset(configuration.sessionPreset) {
            captureSession.sessionPreset = configuration.sessionPreset
        }
        
        guard let inputDevice = cameraInputDevice else { throw CameraError.invalidCaptureDevice }
        
        try configureSessionInput(device: inputDevice)
        try await configureSessionOutputs()
        
        cameraPreview.connect(to: captureSession)
        cameraPreview.adjustPreview(for: inputDevice)
        
        setupRotationCoordinator(for: inputDevice)
    }
    
    internal func switchCaptureDevice(to device: AVCaptureDevice) async throws {
        precondition(activeCameraInput != nil, "Switch capture device requires an existing capture device.")
       
        setConfigurationState(true)
        cameraPreview.freezePreview(true)
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
            
            let sessionIsRunning = self.captureSession.isRunning
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                withAnimation(sessionIsRunning ? .easeInOut(duration: 0.15) : nil) {
                    self.camera?.previewDimming = true
                } completion: {
                    self.cameraPreview.freezePreview(false)
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.camera?.previewDimming = false
                        self.setConfigurationState(false)
                    }
                }
            }
        }
        
        if captureSession.canSetSessionPreset(configuration.sessionPreset) {
            captureSession.sessionPreset = configuration.sessionPreset
        }
        
        guard let inputDevice = cameraInputDevice else { throw CameraError.invalidCaptureDevice }
        try configureSessionInput(device: inputDevice)
        
        guard let camera = await self.camera else { return }
        for output in outputs {
            try output.updateOutput(camera)
        }
        
        cameraPreview.adjustPreview(for: inputDevice)
        setupRotationCoordinator(for: inputDevice)
    }
    
    private func configureSessionInput(device: AVCaptureDevice) throws {
        do {
            if let activeCameraInput {
                captureSession.removeInput(activeCameraInput)
            }
            self.activeCameraInput = try addInput(from: device)
        } catch {
            if let activeCameraInput {
                captureSession.addInput(activeCameraInput)
            }
        }
    }
    
    private func configureSessionOutputs() async throws {
        let outputs: [any CaptureOutput] = if configuration.sessionPreset == .photo {
            [photoOutput] // photo only
        } else {
            [photoOutput, videoOutput] // photo and video
        }
        
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        for output in outputs {
            try addOutput(output.output)
        }
        self.outputs = outputs
        
        guard let camera = await self.camera else { return }
        for output in outputs {
            try output.updateOutput(camera)
        }
    }
    
    private func setupRotationCoordinator(for device: AVCaptureDevice) {
        Task { @MainActor in
            rotationCoordinator = AVCaptureDevice.RotationCoordinator(
                device: device,
                previewLayer: cameraPreview.layer
            )
            observeRotationCoordinator()
        }
    }

    // MARK: - Input
    
    /// The active camera device input used by the session.
    private var activeCameraInput: AVCaptureDeviceInput?
    /// The active capture device used by the session.
    var cameraInputDevice: AVCaptureDevice! {
        didSet {
            guard let cameraInputDevice, activeCameraInput != nil else { return }
            
            Task {
                do {
                    try await switchCaptureDevice(to: cameraInputDevice)
                } catch {
                    logger.error("\(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Makes device input from the capture device and add it to the pipeline if possible.
    @discardableResult
    private func addInput(from inputDevice: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let deviceInput = try AVCaptureDeviceInput(device: inputDevice)
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        } else {
            throw CameraError.failedToAddInput
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
    private func addOutput(_ output: AVCaptureOutput) throws(CameraError) {
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            throw CameraError.failedToAddOutput
        }
    }
    
    // MARK: - Rotation Coordinator
    
    /// A set of observers that observe the properties of `rotationCoordinator`.
    nonisolated(unsafe) private var rotationObservers: Set<AnyCancellable> = []
    /// A rotation coordinator that monitors physical orientation to ensure the level of preview and captured content is relative to gravity.
    nonisolated(unsafe) private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    
    nonisolated private func observeRotationCoordinator() {
        guard let rotationCoordinator else { return }
        rotationObservers.removeAll()
        
        withValueObservation(
            of: rotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelCapture,
            cancellables: &rotationObservers
        ) { [weak self] angle in
            Task { @CameraActor in
                self?.outputs.forEach({ $0.setVideoRotationAngle(angle) })
            }
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
                self?.cameraPreview.preview.videoPreviewLayer.connection?.videoRotationAngle = angle
            }
        }
    }
    
    nonisolated public func withCurrentCaptureDevice(
        perform action: @escaping @CameraActor (AVCaptureDevice) throws -> Void
    ) {
        Task {
            guard let cameraInputDevice = await cameraInputDevice else { return }
            do {
                try cameraInputDevice.lockForConfiguration()
                defer { cameraInputDevice.unlockForConfiguration() }
                
                try await action(cameraInputDevice)
            } catch {
                logger.error("Cannot lock device for configuration: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Actions
    
    @available(macOS, unavailable)
    func setManualFocus(
        pointOfInterst: CGPoint,
        focusMode: AVCaptureDevice.FocusMode,
        exposureMode: AVCaptureDevice.ExposureMode
    ) {
        withCurrentCaptureDevice { device in
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

// MARK: - Auxiliary

extension CameraCoordinator {
    nonisolated private func setConfigurationState(_ isConfiguring: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let currentState = self.camera?.captureSessionState
            
            switch (currentState, isConfiguring) {
                case (.running, true):
                    self.camera?.captureSessionState = .configuring
                case (.configuring, false):
                    self.camera?.captureSessionState = await captureSession.isRunning ? .running : .idle
                default:
                    break
            }
        }
    }
}
