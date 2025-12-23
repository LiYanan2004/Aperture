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
        let camera = await camera
        await MainActor.run {
            self.camera?.captureSessionState = .configuring
        }
        
        captureSession.beginConfiguration()
        defer {
            let sessionIsRunning = self.captureSession.isRunning
            
            self.captureSession.commitConfiguration()
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                withAnimation(sessionIsRunning ? .easeInOut(duration: 0.15) : nil) {
                    self.camera?.previewDimming = true
                } completion: {
                    self.cameraPreview.setPreviewConnectionEnabled(true)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.camera?.previewDimming = false
                        self.camera?.captureSessionState = sessionIsRunning ? .running : .idle
                    }
                }
            }
        }
        
        // MARK: 1. Session
        if captureSession.canSetSessionPreset(configuration.sessionPreset) {
            captureSession.sessionPreset = configuration.sessionPreset
        }
        
        // MARK: 2. Inputs
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        
        guard let inputDevice = cameraInputDevice else { throw CameraError.invalidCaptureDevice }
        self.cameraInput = try addInput(from: inputDevice)
        
        // MARK: 3. Outputs
        self.outputs.forEach {
            captureSession.removeOutput($0.output)
        }
        
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
        self.outputs = outputs
        
        // MARK: 4. Preview
        cameraPreview.connect(to: captureSession)
        cameraPreview.adjustPreview(for: inputDevice)
        cameraPreview.setPreviewConnectionEnabled(false)
        
        // MARK: 5. Rotation Coordinator
        rotationCoordinator = await MainActor.run {
            AVCaptureDevice.RotationCoordinator(
                device: inputDevice,
                previewLayer: cameraPreview.layer
            )
        }
        observeRotationCoordinator()
    }
    
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
}
