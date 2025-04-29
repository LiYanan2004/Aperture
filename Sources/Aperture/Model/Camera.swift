import SwiftUI
import Observation
@preconcurrency import AVFoundation
import OSLog

/// An object reflecting the current camera status.
@Observable
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public final class Camera: NSObject, @unchecked Sendable {
    @ObservationIgnored internal let logger = Logger(subsystem: "MEGAX", category: "Camera")
    
    // MARK: Custom delegates & configurations
    @ObservationIgnored internal var errorHandler: ((CameraError) -> Void)?
    @ObservationIgnored internal var configuration = CameraCaptureConfiguration()
    
    // MARK: UI states
    /// A boolean value indicates whether the shutter should be disabled.
    internal(set) public var shutterDisabled = false
    /// A boolean value indicates system is busy processing caotured photo.
    internal(set) public var isBusyProcessing = false
    internal var dimCameraPreview = 0.0
    /// Recommended rotation angle that respects to current device orientation.
    /// - tips: Apply this angle to your controls if your app only support portait mode.
    internal(set) public var interfaceRotationAngle = Double.zero
    
    // MARK: - Capture Session
    /// Constants that indicate current session status.
    public enum SessionState: Sendable {
        case running, notRunning, committing
    }
    /// Current state of the capture session.
    public internal(set) var sessionState: SessionState = .notRunning
    
    internal let session = AVCaptureSession()
    private var sessionQueue = DispatchQueue(label: "com.liyanan2004.megax.sessionQueue")
    internal var videoDevice: AVCaptureDevice? { videoDeviceInput?.device }
    internal var videoDeviceInput: AVCaptureDeviceInput!
    internal var photoOutput = AVCapturePhotoOutput()
    
    // MARK: - Camera Experience
    #if !os(watchOS) && !os(visionOS)
    @MainActor @ObservationIgnored lazy var cameraPreview: CameraPreview = {
        CameraPreview(session: session)
    }()
    #endif
    @ObservationIgnored private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator!
    @ObservationIgnored private var videoRotationAngleForHorizonLevelPreviewObservation: NSKeyValueObservation?
    @ObservationIgnored private var videoRotationAngleForHorizonLevelCaptureObservation: NSKeyValueObservation?
    @ObservationIgnored private var sceneMonitoring: NSKeyValueObservation?
    @ObservationIgnored private var readinessCoordinator: AVCapturePhotoOutputReadinessCoordinator!
    
    // MARK: - Flash Light
    #if targetEnvironment(simulator)
    /// A boolean value indicates whether the device has flash.
    public var currentDeviceHasFlash: Bool { true } // Enable flash indicator for preview
    #else
    /// A boolean value indicates whether the device has flash.
    public var currentDeviceHasFlash: Bool { videoDevice?.hasFlash ?? false }
    #endif
    /// Current flash mode used by the active capture device.
    public var flashMode: AVCaptureDevice.FlashMode = .auto
    
    // TODO: Macro Control
    @ObservationIgnored private var activePrimaryConstituentDeviceObservation: NSKeyValueObservation?
    var activePrimaryConstituentDevice: AVCaptureDevice?
    @ObservationIgnored private var lensPositionObservation: NSKeyValueObservation?
    var macroControlVisible = false
    var autoSwitchToMacroLens = true {
        willSet {
            configureAutoLensSwitching()
        }
    }
    
    var grantedPermission: Bool {
        get async { await AVCaptureDevice.requestAccess(for: .video) }
    }
    
    /// Configure session and start running the capture pipeline.
    public func startSession() {
        guard session.isRunning == false else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            configureSession()
            session.startRunning()
            Task { @MainActor in
                self.sessionState = .running
            }
        }
    }
    
    /// Stop current capture session.
    public func stopSession() {
        guard session.isRunning else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            session.stopRunning()
            Task { @MainActor in
                self.sessionState = .notRunning
            }
        }
    }
    
    func updateSession(with configuration: CameraCaptureConfiguration) {
        self.configuration = configuration
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            
            configureAutoLensSwitching()
            configurePhotoOutput()
            
            #if (os(iOS) || os(tvOS)) && !targetEnvironment(macCatalyst)
            configureMultitaskAccess()
            configurePreferedStabilizationMode()
            #endif
        }
    }

    // MARK: - Toggle Camera
    /// Constants that indicate the physical position of a capture device.
    public enum CameraSide: Sendable {
        case front, back
        /// Equal representation of this value to `AVCaptureDevice.Position`.
        var position: AVCaptureDevice.Position {
            switch self {
            case .front: .front
            case .back: .back
            }
        }
        mutating func toggle() {
            self = self == .front ? .back : .front
        }
    }
    #if os(macOS) || targetEnvironment(macCatalyst)
    /// Current position of a capture device.
    internal(set) public var cameraSide: CameraSide = .front
    #else
    /// Current position of a capture device.
    internal(set) public var cameraSide: CameraSide = .back
    #endif
    internal var isFrontCamera: Bool { cameraSide == .front }
    internal var isBackCamera: Bool { cameraSide == .back }
    private var toggleCameraTask: Task<Void, Error>?
    
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    func toggleCamera() {
        shutterDisabled = true
        sessionState = .committing
        dimCameraPreview = 0.2
        withAnimation(.easeInOut) {
            cameraSide.toggle()
        }
        toggleCameraTask?.cancel()
        toggleCameraTask = Task {
            try await Task.sleep(for: .seconds(0.3))
            try Task.checkCancellation()
            _toggleCamera(to: findDevice(position: cameraSide.position))
        }
    }
    
    private func _toggleCamera(to videoDevice: AVCaptureDevice?) {
        #if !os(watchOS) && !os(visionOS)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            session.beginConfiguration()

            guard let videoDevice else {
                logger.error("Cannot find an appropriate video device input.")
                return
            }
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                logger.error("Failed to create device input.")
                return
            }
            
            session.removeInput(self.videoDeviceInput)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                // Auto-switching between lens
                configureAutoLensSwitching()
                
                #if os(iOS) || os(tvOS)
                // Set zoom for new device
                // Use main camera for rear camera(s)
                // Use 8MP by default for front camera
                setZoomFactor(
                    isBackCamera ? backCameraDefaultZoomFactor : frontCameraDefaultZoomFactor
                )
                #endif
            } else {
                session.addInput(self.videoDeviceInput)
            }
            
            // Explicitly reconfigure photo output after acquiring a different device
            configurePhotoOutput()
            
            Task { @MainActor in
                self.createDeviceRotationCoordinator()
                // Pause the camera preview flow to make sure transition can be animated well
                self.cameraPreview.preview.videoPreviewLayer.connection?.isEnabled = false
                self.sessionQueue.async { [weak self] in
                    guard let self else { return }
                    
                    // Wait session configuration being committed
                    session.commitConfiguration()
                    
                    // Switch back to main thread to perform animation
                    Task { @MainActor in
                        // Fade out the old preview
                        withAnimation(.bouncy(duration: 0.3)) {
                            self.dimCameraPreview = 0.9
                        }
                    }
                    
                    Task { @MainActor in
                        // Resume preview connection in the middle of the dimming effect
                        try await Task.sleep(for: .seconds(0.15))
                        self.cameraPreview.preview.videoPreviewLayer.connection?.isEnabled = true
                        self.sessionState = .running
                        // Fade in the new preview with a spring animation
                        // to keep the animation velocity if necessary
                        withAnimation(.smooth(duration: 0.3)) {
                            self.dimCameraPreview = 0
                        }
                        self.shutterDisabled = false
                    }
                }
            }
        }
        #endif
    }
    
    // MARK: - Zoom
    /// Current zoom factor of the active device.
    internal(set) public var zoomFactor: CGFloat = 1
    internal var backCameraOpticalZoomFactors: [CGFloat] = []
    internal var backCameraDefaultZoomFactor: CGFloat = 1
    internal var frontCameraDefaultZoomFactor: CGFloat = 1
    
    #if os(iOS) || os(tvOS)
    func setZoomFactor(
        _ zoomFactor: CGFloat,
        withRate rate: Float? = nil,
        animation: Animation? = .smooth(duration: 0.25)
    ) {
        configureCaptureDevice { device in
            if device.isRampingVideoZoom {
                device.cancelVideoZoomRamp()
            }
            
            if let rate {
                device.ramp(toVideoZoomFactor: zoomFactor, withRate: rate)
            } else {
                device.videoZoomFactor = zoomFactor
            }
            withAnimation(animation) {
                self.zoomFactor = zoomFactor
            }
        }
    }
    #endif
    
    // MARK: - Focus
    /// A boolean value indicates whether the focus lock is enabled.
    public internal(set) var focusLocked = false
    
    #if os(iOS) || os(tvOS)
    func setManualFocus(pointOfInterst: CGPoint, focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode) {
        configureCaptureDevice { device in
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
    
    // MARK: - Capture
    /// Capture photo using current active device.
    /// - parameter completionHandler: The action to perform after receiving captured photo.
    public func capturePhoto(completionHandler: @escaping (CapturedPhoto) -> Void) {
        #if !targetEnvironment(simulator)
        let photoSettings = createPhotoSettings()
        readinessCoordinator.startTrackingCaptureRequest(using: photoSettings)
        
        let videoRotationAngle = self.videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelCapture
        
        Task {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoRotationAngle = videoRotationAngle
            }
            let processor = PhotoProcessor()
            let capturedPhotoData = await withCheckedContinuation { (continuation: CheckedContinuation<CapturedPhoto, Never>) in
                processor.setup(continuation: continuation, camera: self)
                photoOutput.capturePhoto(with: photoSettings, delegate: processor)
                readinessCoordinator.stopTrackingCaptureRequest(using: photoSettings.uniqueID)
            }
            completionHandler(capturedPhotoData)
        }
        #endif
    }
    
    // MARK: - Helper Methods
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    private func findDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        #if os(watchOS) || os(visionOS)
        fatalError("Unsupported platforms.")
        let preferedDeviceTypes: [AVCaptureDevice.DeviceType]? = nil
        #else
        let preferedDeviceTypes = configuration.captureDeviceTypes
        #endif
        #if os(macOS)
        var deviceTypes = preferedDeviceTypes ?? [.builtInWideAngleCamera, .continuityCamera]
        #else
        var deviceTypes = preferedDeviceTypes ?? [.builtInTripleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera]
        #endif
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *),
            configuration.preferConstantColor {
            #if os(macOS)
            deviceTypes = [.builtInWideAngleCamera]
            #else
            deviceTypes = [.builtInDualWideCamera, .builtInWideAngleCamera]
            #endif
        }
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first
    }
    
    internal func configureCaptureDevice(_ configure: @escaping (_ device: AVCaptureDevice) throws -> Void) {
        guard let videoDevice else { return }
        do {
            try videoDevice.lockForConfiguration()
            try configure(videoDevice)
            videoDevice.unlockForConfiguration()
        } catch {
            logger.error("Cannot lock device for configuration: \(error.localizedDescription)")
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.sessionPreset = .photo
        
        // Video device input
        #if os(macOS) || targetEnvironment(macCatalyst)
        let videoDevice = findDevice(position: .unspecified)
        #else
        let videoDevice = findDevice(position: .back)
        #endif
        guard let videoDevice else {
            logger.error("Cannot find an appropriate video device input.")
            return
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            logger.error("Failed to create device input.")
            return
        }
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            
            activePrimaryConstituentDevice = videoDevice.activePrimaryConstituent
            activePrimaryConstituentDeviceObservation = videoDevice.observe(\.activePrimaryConstituent, options: .new) { device, change in
                guard let activePrimaryConstituent = change.newValue else { return }
                self.activePrimaryConstituentDevice = activePrimaryConstituent
            }
            
            // Auto-switching between lens
            configureAutoLensSwitching()
            
            Task { @MainActor in
                createDeviceRotationCoordinator()
            }
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            configurePhotoOutput()
        }
        
        let readinessCoordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: photoOutput)
        DispatchQueue.main.async {
            self.readinessCoordinator = readinessCoordinator
            readinessCoordinator.delegate = self
        }
        
        #if (os(iOS) || os(tvOS)) && !targetEnvironment(macCatalyst)
        configureAvailableOpticalZoomsAndDefaultZoomsForCameras()
        configureMultitaskAccess()
        configurePreferedStabilizationMode()
        #endif
    }
   
    private func configureAutoLensSwitching(enabled: Bool? = nil) {
        configureCaptureDevice { device in
            #if os(iOS)
            if let wideCameraZF = device.virtualDeviceSwitchOverVideoZoomFactors.first {
                self.setZoomFactor(CGFloat(truncating: wideCameraZF), animation: nil)
            }
            #endif
            guard !device.fallbackPrimaryConstituentDevices.isEmpty else { return }
            let enabled = enabled ?? self.configuration.autoSwitchingLens
            device.setPrimaryConstituentDeviceSwitchingBehavior(
                enabled ? .auto : .locked,
                restrictedSwitchingBehaviorConditions: []
            )
        }
    }
    
    private func configurePhotoOutput() {
        #if !os(watchOS) && !os(visionOS)
        photoOutput.maxPhotoQualityPrioritization = configuration.preferedQualityPrioritization
        let supportedMaxDimensions = self.videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions
        photoOutput.maxPhotoDimensions = supportedMaxDimensions.last!
        #endif
        
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if photoOutput.isAutoDeferredPhotoDeliverySupported {
            photoOutput.isAutoDeferredPhotoDeliveryEnabled = configuration.preferAutoDeferredPhotoDelivery
        }
        #endif
        if photoOutput.isZeroShutterLagSupported {
            photoOutput.isZeroShutterLagEnabled = configuration.preferZeroShutterLag
        }
        if photoOutput.isResponsiveCaptureSupported {
            photoOutput.isResponsiveCaptureEnabled = configuration.preferResponsiveCapture
            if photoOutput.isFastCapturePrioritizationSupported {
                photoOutput.isFastCapturePrioritizationEnabled = configuration.preferFastCapturePrioritization
            }
        }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *) {
            if photoOutput.isConstantColorSupported {
                photoOutput.isConstantColorEnabled = configuration.preferConstantColor
            }
        }
    }
    
    private func createPhotoSettings() -> AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
        #if !os(watchOS) && !os(visionOS)
        photoSettings.photoQualityPrioritization = configuration.preferedQualityPrioritization
        if photoOutput.supportedFlashModes.contains(flashMode) {
            photoSettings.flashMode = flashMode
        } else {
            self.flashMode = .off
        }
        #endif
        
        repeat {
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *),
               configuration.preferConstantColor {
                if photoOutput.isConstantColorSupported == false {
                    logger.error("[Constant Color] Current device doesn't support constant color.")
                    break
                } else if flashMode == .off {
                    logger.error("[Constant Color] Constant color is unavailable when flash mode is off.")
                    break
                }
                
                photoSettings.isConstantColorEnabled = configuration.preferConstantColor
                photoSettings.isConstantColorFallbackPhotoDeliveryEnabled = configuration.enableConstantColorFallbackDelivery
            }
        } while false
        
        #if os(iOS) || os(tvOS)
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        #endif
        
        return photoSettings
    }
    
    @MainActor
    private func createDeviceRotationCoordinator() {
        #if !os(watchOS) && !os(visionOS)
        let videoPreviewLayer = cameraPreview.preview.videoPreviewLayer
        videoDeviceRotationCoordinator = AVCaptureDevice.RotationCoordinator(device: videoDeviceInput.device, previewLayer: videoPreviewLayer)
        videoPreviewLayer.connection?.videoRotationAngle = videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelPreview
        self.setInterfaceRotationAngle(videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelCapture)
        
        videoRotationAngleForHorizonLevelPreviewObservation = videoDeviceRotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { _, change in
            guard let videoRotationAngleForHorizonLevelPreview = change.newValue else { return }
            videoPreviewLayer.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview
        }
        
        videoRotationAngleForHorizonLevelCaptureObservation = videoDeviceRotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { _, change in
            guard let videoRotationAngleForHorizonLevelCapture = change.newValue else { return }
            Task { @MainActor in
                self.setInterfaceRotationAngle(videoRotationAngleForHorizonLevelCapture)
            }
        }
        #endif
    }
    
    @MainActor
    private func setInterfaceRotationAngle(_ videoRotationAngleForHorizonLevelCapture: CGFloat) {
        // We need to rotate element based on `videoRotationAngleForHorizonLevelCapture`
        var targetRotationAngle = Double(videoRotationAngleForHorizonLevelCapture)
        if targetRotationAngle >= 180 {
            targetRotationAngle -= 360
        }
        // Fix the angle to make portait be 0 degree
        targetRotationAngle = 90 - targetRotationAngle

        // Only rotate minimum degrees
        var currentRotationAngle = self.interfaceRotationAngle
        while currentRotationAngle > 360 || currentRotationAngle < 0 {
            let `operator` = currentRotationAngle > 0 ? -1.0 : 1.0
            currentRotationAngle += (`operator` * 360)
        }
        withAnimation(nil) {
            self.interfaceRotationAngle = currentRotationAngle
        }
        let rotationAngle = targetRotationAngle - currentRotationAngle
        let clockwiseRotationAngle: Double
        let antiClockwiseRotationAngle: Double
        
        if rotationAngle > 0 {
            clockwiseRotationAngle = abs(rotationAngle)
            antiClockwiseRotationAngle = abs(rotationAngle - 360)
        } else {
            clockwiseRotationAngle = abs(rotationAngle + 360)
            antiClockwiseRotationAngle = abs(rotationAngle)
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            self.interfaceRotationAngle = if antiClockwiseRotationAngle < clockwiseRotationAngle {
                currentRotationAngle - antiClockwiseRotationAngle
            } else {
                currentRotationAngle + clockwiseRotationAngle
            }
        }
    }
    
    #if os(iOS) || os(tvOS)
    private func configureAvailableOpticalZoomsAndDefaultZoomsForCameras() {
        if let backCamera = findDevice(position: .back) {
            var backCameraOpticalZoomFactors = backCamera
                .virtualDeviceSwitchOverVideoZoomFactors
                .map(CGFloat.init(truncating:))
            
            self.backCameraDefaultZoomFactor = backCameraOpticalZoomFactors.first ?? 1
            
            // This device features a 48MP camera, so we can add 2x as an optical zoom option.
            let support48MP = backCamera
                .constituentDevices
                .first(where: { $0.deviceType == .builtInWideAngleCamera })?
                .formats
                .flatMap(\.supportedMaxPhotoDimensions)
                .reversed() // It should be the last one, so reverse the array make searching faster
                .contains(where: { $0.width * $0.height > 48_000_000 })
            if support48MP ?? false {
                backCameraOpticalZoomFactors.insert(
                    (backCameraOpticalZoomFactors.first ?? 1) * 2,
                    at: backCameraOpticalZoomFactors.isEmpty ? 0 : 1
                )
            }
            self.backCameraOpticalZoomFactors = backCameraOpticalZoomFactors
        }
        
        if let frontCamera = findDevice(position: .front) {
            let support12MP = frontCamera
                .formats
                .flatMap(\.supportedMaxPhotoDimensions)
                .reversed() // It should be the last one, so reverse the array make searching faster
                .contains(where: { $0.width * $0.height > 12_000_000 })
            if support12MP {
                self.frontCameraDefaultZoomFactor = 1.3
            }
        }
    }
    
    @available(macCatalyst, unavailable)
    private func configureMultitaskAccess() {
        if session.isMultitaskingCameraAccessSupported {
            session.isMultitaskingCameraAccessEnabled = configuration.captureWhenMultiTasking
        }
    }
    
    private func configurePreferedStabilizationMode() {
        for connection in session.connections {
            guard connection.isVideoStabilizationSupported else { continue }
            connection.preferredVideoStabilizationMode = configuration.stabilizationMode
        }
    }
    #endif
}
