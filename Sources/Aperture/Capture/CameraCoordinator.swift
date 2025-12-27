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
    @MainActor weak var camera: Camera!
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
            do {
                try configureSession()
            } catch {
                logger.error("Failed to switch configuration: \(error.localizedDescription)")
            }
        }
    }
    
    /// Configure current session and corresponding capture pipeline with current configuration and devices.
    internal func configureSession() throws {
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
        
        configureSessionInput(device: inputDevice)
        configureSessionOutputs()
        
        cameraPreview.connect(to: captureSession)
        cameraPreview.adjustPreview(for: inputDevice)
        
        setupRotationCoordinator(for: inputDevice)
        
        updateOutputServices()
    }
    
    internal func switchCaptureDevice(to device: AVCaptureDevice) throws {
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
        
        configureSessionInput(device: device)
        cameraPreview.adjustPreview(for: device)
        setupRotationCoordinator(for: device)
        updateOutputServices()
    }
    
    private func configureSessionInput(device: AVCaptureDevice) {
        $zoomInformationObservers.cancelAll()
        
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
        
        let displayZoomFactorMultiplier: CGFloat
        if #available(iOS 18.0, macOS 14.0, *) {
            displayZoomFactorMultiplier = observeDisplayZoomFactorMultiplier()
        } else {
            let wideAngleCameraZoomFactor = self.wideAngleCameraZoomFactor
            displayZoomFactorMultiplier = wideAngleCameraZoomFactor
            updateCamera { camera in
                camera.displayZoomFactorMultiplier = 1 / wideAngleCameraZoomFactor
            }
        }
        #if os(iOS)
        withCurrentCaptureDevice { device in
            device.videoZoomFactor = 1 / displayZoomFactorMultiplier
        }
        observeDeviceZoomFactor()
        #endif
        
        let deviceHasFlash = self.cameraInputDevice.hasFlash
        updateCamera { camera in
            camera.flash.deviceEligible = deviceHasFlash
        }
    }
    
    private func configureSessionOutputs() {
        guard let activeCameraInput else { return }
        
        let services = configuration.services
        let activeOutputs = self.activeOutputs
        
        self.activeOutputs.forEach {
            captureSession.removeOutput($0)
        }
        
        self.activeOutputs = []
        do {
            for service in services {
                func makeOutput<S: OutputService>(service: S) -> AVCaptureOutput {
                    let coordinator: S.Coordinator
                    if let existingCoordinator = outputServiceCoordinators.first(byUnwrapping: {
                        $0 as? S.Coordinator
                    }) {
                        coordinator = existingCoordinator
                    } else {
                        coordinator = service.makeCoordinator()
                        outputServiceCoordinators.append(coordinator)
                    }
                    
                    // FIXME: This is a backdoor for `PhotoCaptureService`
                    if let coordinator = coordinator as? PhotoCaptureService.Coordinator {
                        coordinator.cameraCoordinator = self
                    }
                    
                    let context = OutputServiceContext<S>(
                        coordinator: coordinator,
                        session: captureSession,
                        input: activeCameraInput
                    )
                    return service.makeOutput(context: context)
                }
                
                let output = _openExistential(service, do: makeOutput(service:))
                self.activeOutputs.append(output)
                try addOutput(output)
            }
        } catch {
            self.activeOutputs.forEach({ captureSession.removeOutput($0) })
            
            activeOutputs.forEach({ captureSession.addOutput($0) })
            self.activeOutputs = activeOutputs
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
    var activeCameraInput: AVCaptureDeviceInput?
    /// The active capture device used by the session.
    var cameraInputDevice: AVCaptureDevice! {
        didSet {
            guard let cameraInputDevice, activeCameraInput != nil else { return }
            
            do {
                try switchCaptureDevice(to: cameraInputDevice)
            } catch {
                logger.error("\(error.localizedDescription)")
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
    
    @discardableResult
    @available(iOS 18.0, macOS 14.0, *)
    private func observeDisplayZoomFactorMultiplier() -> CGFloat {
        withValueObservation(
            of: cameraInputDevice,
            keyPath: \.displayVideoZoomFactorMultiplier,
            cancellables: &zoomInformationObservers
        ) { [weak self] displayVideoZoomFactorMultiplier in
            self?.updateCamera { camera in
                camera.displayZoomFactorMultiplier = displayVideoZoomFactorMultiplier
            }
        }
        
        return cameraInputDevice.displayVideoZoomFactorMultiplier
    }
    #if os(iOS)
    /// A boolean value indicating whether the capture device is setting its zoom factor.
    package var isSettingZoomFactor = false
    private func observeDeviceZoomFactor() {
        withValueObservation(
            of: cameraInputDevice,
            keyPath: \.videoZoomFactor,
            cancellables: &zoomInformationObservers
        ) { [weak self] videoZoomFactor in
            guard let self else { return }
            guard !self.isSettingZoomFactor else { return }
            self.updateCamera { @MainActor camera in
                camera.zoomFactor = videoZoomFactor
            }
        }
    }
    #endif
    @Cancellables private var zoomInformationObservers
    
    private var wideAngleCameraZoomFactor: CGFloat {
        var switchOverZoomFactor: CGFloat = 1
        
        guard let device = self.cameraInputDevice else { return switchOverZoomFactor }
        
        #if os(iOS)
        let wideAngleCameraOffset = device.constituentDevices
            .enumerated()
            .first(where: { $0.element.deviceType == .builtInWideAngleCamera })?
            .offset
        guard let wideAngleCameraOffset else { return switchOverZoomFactor }
        
        // "These factors progress in the same order as the devices listed in that property." -- documentation
        // Since switchOverVideoZoomFactor count is N - 1 (where N == constituentDevices.count), shift left by one to remove 1.0x
        let switchOverZoomFactorOffset = wideAngleCameraOffset - /* 1.0x */ 1
        guard switchOverZoomFactorOffset >= 0 else { return switchOverZoomFactor }
        
        switchOverZoomFactor = CGFloat(
            truncating: device.virtualDeviceSwitchOverVideoZoomFactors[switchOverZoomFactorOffset]
        )
        #endif
        
        return switchOverZoomFactor
    }
    
    // MARK: - Output
    
    /// The active camera device input used by the session.
    var activeOutputs: [AVCaptureOutput] = []
    
    var outputServiceCoordinators: [Any] = []
    
    /// Adds the capture output to the pipeline if possible.
    private func addOutput(_ output: AVCaptureOutput) throws(CameraError) {
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            throw CameraError.failedToAddOutput
        }
    }
    
    /// Gets current context of the output service.
    internal func outputContext<T: OutputService>(for: T.Type) -> OutputServiceContext<T>? {
        guard let activeCameraInput else { return nil }
        
        let coordinator = outputServiceCoordinators.first(byUnwrapping: { $0 as? T.Coordinator })
        guard let coordinator else { return nil }
        
        return .init(coordinator: coordinator, session: captureSession, input: activeCameraInput)
    }
    
    private func updateOutputServices() {
        func updateOutput<S: OutputService>(service: S) throws {
            let output = activeOutputs.first(byUnwrapping: { $0 as? S.Output })
            let context = outputContext(for: S.self)
            
            guard let output, let context else { throw CameraError.failedToUpdateOutputSevice }
            service.updateOutput(output: output, context: context)
        }
        
        for service in configuration.services {
            do {
                try _openExistential(service, do: updateOutput(service:))
            } catch {
                logger.error("Failed to update output service (\(String(reflecting: service))): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Rotation Coordinator
    
    /// A set of observers that observe the properties of `rotationCoordinator`.
    @Cancellables private var rotationObservers
    /// A rotation coordinator that monitors physical orientation to ensure the level of preview and captured content is relative to gravity.
    nonisolated(unsafe) private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    
    nonisolated private func observeRotationCoordinator() {
        guard let rotationCoordinator else { return }
        $rotationObservers.cancelAll()
        
        withValueObservation(
            of: rotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelCapture,
            cancellables: &$rotationObservers.wrappedValue // Swift does not support `nonisolated(unsafe)` directly on properties with property wrappers
        ) { [weak self] angle in
            Task { @CameraActor in
                guard let self else { return }
                for output in self.activeOutputs {
                    output.connection(with: .video)?.videoRotationAngle = angle
                }
            }
            self?.updateCamera {
                $0.captureRotationAngle = angle
            }
        }
        
        withValueObservation(
            of: rotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelPreview,
            cancellables: &$rotationObservers.wrappedValue // Swift does not support `nonisolated(unsafe)` directly on properties with property wrappers
        ) { [weak self] angle in
            self?.updateCamera { @MainActor camera in
                camera.previewRotationAngle = angle
                self?.cameraPreview.preview.videoPreviewLayer.connection?.videoRotationAngle = angle
            }
        }
    }
    
    public func withCurrentCaptureDevice(
        perform action: @escaping (AVCaptureDevice) throws -> Void
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

// MARK: - Auxiliary

extension CameraCoordinator {
    nonisolated private func updateCamera(
        perform action: @escaping (Camera) async -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            precondition(self.camera != nil, "Camera is not available.")
            await action(self.camera)
        }
    }
    
    nonisolated private func setConfigurationState(_ isConfiguring: Bool) {
        updateCamera { camera in
            let currentState = camera.captureSessionState
            
            switch (currentState, isConfiguring) {
                case (.running, true):
                    camera.captureSessionState = .configuring
                case (.configuring, false):
                    camera.captureSessionState = await self.captureSession.isRunning ? .running : .idle
                default:
                    break
            }
        }
    }
}
