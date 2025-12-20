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

@Observable
open class CameraSession: Logging {
    @ObservationIgnored lazy var logger = Logger(
        subsystem: "Aperature",
        category: "\(Self.self)"
    )
    
    #if os(iOS) || os(macOS)
    @ObservationIgnored lazy var cameraPreview: CameraPreview = {
        CameraPreview(session: captureSession)
    }()
    #endif
    
    public var camera: any Camera {
        willSet {
            
        }
    }

    @MainActor
    internal func _setupRotationCoordinator() {
        guard let deviceInput else { return }
        if rotationCoordinator == nil {
            rotationCoordinator = AVCaptureDevice.RotationCoordinator(
                device: deviceInput.device,
                previewLayer: cameraPreview.preview.videoPreviewLayer
            )
        }
        
        withValueObservation(
            of: rotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelPreview,
            cancellables: &_rotationCoordinatorObservers
        ) { [weak self] angle in
            self?.cameraPreview.preview.videoPreviewLayer.connection?.videoRotationAngle = angle
            self?.captureRotationAngle = angle
        }
        
        withValueObservation(
            of: rotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelPreview,
            cancellables: &_rotationCoordinatorObservers
        ) { [weak self] angle in
            self?.previewRotationAngle = angle
        }
    }
    
    @ObservationIgnored private var _rotationCoordinatorObservers: Set<AnyCancellable> = []
    @ObservationIgnored private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    public var previewRotationAngle: CGFloat = 0
    public var captureRotationAngle: CGFloat = 0
    
    /// The aspect ratio (width / height) of the currently-selected video format.
    private var cameraAspectRatio: CGFloat {
        guard let device = camera.device else {
            return 1.0
        }
        let formatDescription = device.activeFormat.formatDescription
        let dims = CMVideoFormatDescriptionGetDimensions(formatDescription)
        return CGFloat(dims.width) / CGFloat(dims.height)
    }
    
    public let captureSession = AVCaptureSession()
    open var sessionPreset: AVCaptureSession.Preset? {
        nil
    }
    
    internal var deviceInput: AVCaptureDeviceInput?
    internal let output: AVCaptureOutput
    
    internal(set) public var previewDimming = false
    internal(set) public var isBusyProcessing = false
    internal(set) public var shutterDisabled = false
    
    #if os(iOS)
    public var zoomFactor: CGFloat = 1.0 {
        willSet {
            withCurrentCaptureDevice { device in
                guard newValue != zoomFactor else { return }
                device.videoZoomFactor = zoomFactor
            }
        }
    }
    #endif
    
    public internal(set) var focusLocked = false
    
    #if os(iOS)
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
    #endif
    
    public func withCurrentCaptureDevice(
        perform action: (AVCaptureDevice) throws -> Void
    ) {
        let device = camera.device
        guard let device else { return }
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            try action(device)
        } catch {
            logger.error("Cannot lock device for configuration: \(error.localizedDescription)")
        }
    }

    public init(camera: any Camera, output: AVCaptureOutput) {
        self.camera = camera
        self.output = output
    }
    
    internal func setupSession() async throws {
        guard await CameraSession.isAccessible else { throw CameraError.permissionDenied }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        if let sessionPreset {
            captureSession.sessionPreset = sessionPreset
        }
        
        guard let device = camera.device else { throw CameraError.invalidCaptureDevice }
        let deviceInput = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(deviceInput), deviceInput != self.deviceInput {
            self.deviceInput = deviceInput
            captureSession.addInput(deviceInput)
        }

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
    }
    
    public static var isAccessible: Bool {
        get async {
            await AVCaptureDevice.requestAccess(for: .video)
        }
    }
}
