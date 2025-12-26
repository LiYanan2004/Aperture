import SwiftUI
import Observation
@preconcurrency import AVFoundation
import OSLog
import Combine

/// An object reflecting the current camera status.
@Observable
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public final class CameraManager: NSObject, @unchecked Sendable {
    @ObservationIgnored package let logger = Logger(subsystem: "Aperture", category: "Camera")
    
    // MARK: Custom delegates & configurations
    @ObservationIgnored internal var configuration = CaptureConfiguration()
    
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
    public internal(set) var captureSessionState: SessionState = .notRunning
    
    internal let session = AVCaptureSession()
    private var sessionQueue = DispatchQueue(label: "com.liyanan2004.Aperture.sessionQueue")
    internal var videoDevice: AVCaptureDevice? { videoDeviceInput?.device }
    internal var videoDeviceInput: AVCaptureDeviceInput!
    internal var photoOutput = AVCapturePhotoOutput()
    
    // MARK: - Camera Experience
    #if !os(watchOS) && !os(visionOS)
    @MainActor @ObservationIgnored lazy var cameraPreview: CameraPreview = {
        CameraPreview(session: session)
    }()
    #endif
    /// The aspect ratio (width / height) of the currently-selected video format.
    private var rawCameraAspectRatio: CGFloat {
        // Assuming you have a stored reference to the active AVCaptureDevice:
        guard let device = self.videoDevice else {
            return 1.0
        }
        let formatDescription = device.activeFormat.formatDescription
        let dims = CMVideoFormatDescriptionGetDimensions(formatDescription)
        return CGFloat(dims.width) / CGFloat(dims.height)
    }
    
    var cameraPreviewAspectRatio: CGFloat {
        let deviceIsLandscaped = interfaceRotationAngle.truncatingRemainder(dividingBy: 180) != 0
        return deviceIsLandscaped ? rawCameraAspectRatio : 1 / rawCameraAspectRatio
    }
    @ObservationIgnored private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator!
    @ObservationIgnored internal var deviceCoordinatorObservations: Set<AnyCancellable> = []
    
    @ObservationIgnored private lazy var readinessCoordinator: AVCapturePhotoOutputReadinessCoordinator? = {
        #if os(iOS)
        let coordinator = AVCapturePhotoOutputReadinessCoordinator(
            photoOutput: photoOutput
        )
        coordinator.delegate = self
        return coordinator
        #else
        nil
        #endif
    }()
    
    // MARK: - Flash Light
    #if targetEnvironment(simulator)
    /// A boolean value indicates whether the device has flash.
    public var currentDeviceHasFlash: Bool { true } // Enable flash indicator for preview
    #else
    /// A boolean value indicates whether the device has flash.
    public var currentDeviceHasFlash: Bool { videoDevice?.hasFlash ?? false }
    #endif
    /// Current flash mode used by the active capture device.
    public var flashMode: CameraFlashMode = .auto
    
    var grantedPermission: Bool {
        get async { await AVCaptureDevice.requestAccess(for: .video) }
    }
    
    /// Configure session and start running the capture coordinator.
    public func startSession() {
        guard session.isRunning == false else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            configureSession()
            session.startRunning()
            Task { @MainActor in
                self.captureSessionState = self.session.isRunning ? .running : .notRunning
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
                self.captureSessionState = .notRunning
            }
        }
    }
    
    func startOrUpdateSession(with configuration: CaptureConfiguration) {
        self.configuration = configuration
        if session.isRunning {
            updateSession(with: configuration)
        } else {
            startSession()
        }
    }
    
    func updateSession(with configuration: CaptureConfiguration) {
        self.configuration = configuration
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            
            configureAutoLensSwitching()
            configurePhotoOutput()
            
            #if (os(iOS) || os(tvOS)) && !targetEnvironment(macCatalyst)
            configureMultitaskAccess()
            configurePreviewStatabilizationMode()
            #endif
        }
    }

    // MARK: - Toggle Camera
    /// Current position of a capture device.
    public var cameraPosition: CameraPosition = .platformDefault {
        didSet {
            #if os(iOS)
            disableUIInteractionAndToggleCamera()
            #endif
        }
    }
    internal var isFrontCamera: Bool { cameraPosition == .front }
    internal var isBackCamera: Bool {
        #if os(macOS)
        false
        #else
        cameraPosition == .back
        #endif
    }
    private var toggleCameraTask: Task<Void, Error>?
    
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    private func disableUIInteractionAndToggleCamera() {
        shutterDisabled = true
        captureSessionState = .committing
        if cameraPosition == .back {
            backCameraDisplayZoomFactor = currentDeviceDefaultZoomFactor
        }
        dimCameraPreview = 0.2
        toggleCameraTask?.cancel()
        toggleCameraTask = Task {
            try await Task.sleep(for: .seconds(0.3))
            try Task.checkCancellation()
            _toggleCamera(to: findDevice(position: cameraPosition._avCaptureDevicePosition))
        }
    }
    
    private func _toggleCamera(to videoDevice: AVCaptureDevice?) {
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
                
                zoomFactor = currentDeviceDefaultZoomFactor
                
                // Auto-switching between lens
                configureAutoLensSwitching()
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
                        // Fade out the old preview
                        withAnimation(.bouncy(duration: 0.3)) {
                            self.dimCameraPreview = 0.9
                        }
                    }
                    
                    Task { @MainActor in
                        // Resume preview connection in the middle of the dimming effect
                        try await Task.sleep(for: .seconds(0.15))
                        self.cameraPreview.preview.videoPreviewLayer.connection?.isEnabled = true
                        self.captureSessionState = .running
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
    }
    
    // MARK: - Zoom
    
    var zoomFactor: CGFloat = 1.0 {
        didSet {
            #if os(macOS)
            fatalError("[MISUSE] zoom factor does not support on macOS.")
            #else
            updateZoomFactorIfNeeded()
            #endif
        }
    }
    var backCameraDisplayZoomFactor: CGFloat = 1.0
    
    var backCameraOpticalZoomRanges: [Range<CGFloat>] = [1..<(CGFloat.greatestFiniteMagnitude)]
    var backCameraDefaultZoomFactor: CGFloat = 1
    var frontCameraDefaultZoomFactor: CGFloat = 1
    var currentDeviceDefaultZoomFactor: CGFloat {
        isBackCamera ? backCameraDefaultZoomFactor : frontCameraDefaultZoomFactor
    }
    
    @available(macOS, unavailable)
    func updateZoomFactorIfNeeded() {
        configureCaptureDevice { [zoomFactor] device in
            guard zoomFactor != device.videoZoomFactor else { return }
            device.videoZoomFactor = zoomFactor
        }
    }
    
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
    public func capturePhoto() async -> CapturedPhoto {
        #if !targetEnvironment(simulator)
        let photoSettings = createPhotoSettings()
        readinessCoordinator?.startTrackingCaptureRequest(using: photoSettings)
        
        let videoRotationAngle = self.videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelCapture
        
        if let photoOutputConnection = self.photoOutput.connection(with: .video) {
            photoOutputConnection.videoRotationAngle = videoRotationAngle
        }
        let processor = PhotoProcessor()
        let capturedPhotoData = await withCheckedContinuation { (continuation: CheckedContinuation<CapturedPhoto, Never>) in
            processor.setup(continuation: continuation, camera: self)
            photoOutput.capturePhoto(with: photoSettings, delegate: processor)
            readinessCoordinator?.stopTrackingCaptureRequest(using: photoSettings.uniqueID)
        }
        return capturedPhotoData
        #else
        fatalError("Not Supported.")
        #endif
    }
    
    // MARK: - Helper Methods
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    private func findDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let preferedDeviceTypes = configuration.cameraSettings.captureDeviceTypes
        #if os(macOS)
        var deviceTypes = preferedDeviceTypes ?? [.builtInWideAngleCamera, .continuityCamera]
        #else
        var deviceTypes = preferedDeviceTypes ?? [.builtInTripleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera]
        #endif
        // Device requirements for capturing photos with constant color mode.
        // https://developer.apple.com/cn/videos/play/wwdc2024/10162?time=676
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *),
           configuration.wantsCaptureOptions(.constantColor) {
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
    
    func configureCaptureDevice(
        _ configure: @escaping (_ device: AVCaptureDevice) throws -> Void
    ) {
        guard let videoDevice else { return }
        do {
            try videoDevice.lockForConfiguration()
            try configure(videoDevice)
            videoDevice.unlockForConfiguration()
        } catch {
            logger.error("Cannot lock device for configuration: \(error.localizedDescription)")
        }
    }
    
    func configureCaptureDevice(
        _ configure: @escaping (_ device: AVCaptureDevice) async throws -> Void
    ) async {
        guard let videoDevice else { return }
        do {
            try videoDevice.lockForConfiguration()
            try await configure(videoDevice)
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
            
            #if os(iOS)
            if let wideAngleCameraZoomFactor = videoDevice.virtualDeviceSwitchOverVideoZoomFactors.first {
                self.zoomFactor = CGFloat(truncating: wideAngleCameraZoomFactor)
                self.backCameraDisplayZoomFactor = self.zoomFactor
            }
            #endif
            
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
        
        #if (os(iOS) || os(tvOS)) && !targetEnvironment(macCatalyst)
        configureAvailableOpticalZoomsAndDefaultZoomsForCameras()
        configureMultitaskAccess()
        configurePreviewStatabilizationMode()
        #endif
    }
   
    private func configureAutoLensSwitching(enabled: Bool? = nil) {
        configureCaptureDevice { device in
            guard !device.fallbackPrimaryConstituentDevices.isEmpty else { return }
            let enabled = enabled ?? self.configuration.cameraSettings.autoLensSwitching
            device.setPrimaryConstituentDeviceSwitchingBehavior(
                enabled ? .auto : .locked,
                restrictedSwitchingBehaviorConditions: []
            )
        }
    }
    
    private func configurePhotoOutput() {
        #if !os(watchOS) && !os(visionOS)
        photoOutput.maxPhotoQualityPrioritization = configuration.photoSettings.qualityPrioritization
        let supportedMaxDimensions = self.videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions
        photoOutput.maxPhotoDimensions = supportedMaxDimensions.last!
        #endif
        
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if photoOutput.isAutoDeferredPhotoDeliverySupported {
            photoOutput.isAutoDeferredPhotoDeliveryEnabled = configuration.wantsCaptureOptions(.autoDeferredPhotoDelivery)
        }
        #endif
        if photoOutput.isZeroShutterLagSupported {
            photoOutput.isZeroShutterLagEnabled = configuration.wantsCaptureOptions(.zeroShutterLag)
        }
        if photoOutput.isResponsiveCaptureSupported {
            photoOutput.isResponsiveCaptureEnabled = configuration.wantsCaptureOptions(.responsiveCapture)
            if photoOutput.isFastCapturePrioritizationSupported {
                photoOutput.isFastCapturePrioritizationEnabled = configuration.wantsCaptureOptions(.fastCapturePrioritization)
            }
        }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *) {
            if photoOutput.isConstantColorSupported {
                photoOutput.isConstantColorEnabled = configuration.wantsCaptureOptions(.constantColor)
            }
        }
    }
    
    private func createPhotoSettings() -> AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
        photoSettings.photoQualityPrioritization = configuration.photoSettings.qualityPrioritization
        if photoOutput.supportedFlashModes.contains(flashMode.rawValue) {
            photoSettings.flashMode = flashMode.rawValue
        } else {
            self.flashMode = .off
        }
        
        repeat {
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *),
               configuration.wantsCaptureOptions(.constantColor) {
                if photoOutput.isConstantColorSupported == false {
                    logger.error("[Constant Color] Current device doesn't support constant color.")
                    break
                }
                if flashMode == .off {
                    logger.error("[Constant Color] Constant color is unavailable when flash mode is off.")
                    break
                }
                
                photoSettings.isConstantColorEnabled = true
                photoSettings.isConstantColorFallbackPhotoDeliveryEnabled = configuration.wantsCaptureOptions(.constantColorFallbackDelivery)
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
        
        deviceCoordinatorObservations = []
        
        withValueObservation(
            of: videoDeviceRotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelPreview,
            cancellables: &deviceCoordinatorObservations
        ) { videoRotationAngleForHorizonLevelPreview in
            videoPreviewLayer.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview
        }

        withValueObservation(
            of: videoDeviceRotationCoordinator,
            keyPath: \.videoRotationAngleForHorizonLevelCapture,
            cancellables: &deviceCoordinatorObservations
        ) { [weak self] videoRotationAngleForHorizonLevelCapture in
            Task { @MainActor in
                guard let self else { return }
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
            self.backCameraOpticalZoomRanges = zip(
                [1] + backCameraOpticalZoomFactors,
                backCameraOpticalZoomFactors + [CGFloat.greatestFiniteMagnitude]
            ).map({ $0.0..<($0.1) })
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
            session.isMultitaskingCameraAccessEnabled = configuration.multiTasking
        }
    }
    
    private func configurePreviewStatabilizationMode() {
        for connection in session.connections {
            guard connection.videoPreviewLayer != nil else { continue }
            connection.preferredVideoStabilizationMode = configuration.previewStabilizationMode
        }
    }
    #endif
}
