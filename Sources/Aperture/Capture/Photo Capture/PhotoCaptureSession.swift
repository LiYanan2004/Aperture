//
//  PhotoCaptureSession.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import Foundation
import AVFoundation
import Observation
import Combine

@Observable
public class PhotoCaptureSession: CameraSession {
    internal var photoOutput: AVCapturePhotoOutput {
        self.output as! AVCapturePhotoOutput
    }
    
    public var captureOptions: RequestedCaptureOptions
    public override var sessionPreset: AVCaptureSession.Preset? {
        .photo // Cannot override mutable property with read-only property 'sessionPreset'
    }
    
    public init(
        camera: any Camera,
        captureOptions: RequestedCaptureOptions = []
    ) {
        self.captureOptions = captureOptions
        super.init(camera: camera, output: AVCapturePhotoOutput())
    }
    
    override func setupSession() async throws {
        try await super.setupSession()
        
        _configurePreviewStabilizationMode()
        _setupFusionCameraIfNecessary()
        _configurePhotoOutput()
    }
    
    public func takeStillPhoto(configuration: PhotoConfiguration = .init()) async throws -> CapturedPhoto {
        #if !targetEnvironment(simulator)
        let photoSettings = try photoSettings(configuration: configuration)

//        if let photoOutputConnection = self.photoOutput.connection(with: .video) {
//            photoOutputConnection.videoRotationAngle = previewRotationAngle.videoRotationAngleForHorizonLevelCapture
//        }
        
        let capturedPhoto = await withPhotoOutputReadinessCoordinatorTracking(
            photoSettings: photoSettings
        ) {
            await withCheckedContinuation { continuation in
                let delegate = PhotoCaptureDelegate(
                    session: self,
                    continuation: continuation
                )
                inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = delegate

                photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
            }
        }
        
        inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = nil
        
        return capturedPhoto
        #else
        fatalError("Not Supported.")
        #endif
    }
    
    private func photoSettings(configuration: PhotoConfiguration) throws -> AVCapturePhotoSettings {
        guard let device = camera.device else { throw CameraError.invalidCaptureDevice }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
        photoSettings.photoQualityPrioritization = configuration.qualityPrioritization
        
        if photoOutput.supportedFlashModes.contains(device.flashMode) {
            photoSettings.flashMode = device.flashMode
        }
        
        @available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *)
        func _enableConstantColorIfRequestedAndEligible() {
            guard captureOptions.contains(.constantColor) else { return }
            guard photoOutput.isConstantColorSupported else {
                logger.error("[Constant Color] Current device doesn't support constant color.")
                return
            }
            guard device.flashMode == .off else {
                logger.error("[Constant Color] Constant color is unavailable when flash mode is off.")
                return
            }
            
            photoSettings.isConstantColorEnabled = true
            photoSettings.isConstantColorFallbackPhotoDeliveryEnabled = true
        }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *) {
            _enableConstantColorIfRequestedAndEligible()
        }
        
        #if os(iOS) || os(tvOS)
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        #endif
        
        return photoSettings
    }
    
    private func withPhotoOutputReadinessCoordinatorTracking<T>(
        photoSettings: AVCapturePhotoSettings,
        perform action: () async throws -> T
    ) async rethrows -> T {
        var readinessCoordinator: AVCapturePhotoOutputReadinessCoordinator?
        #if os(iOS)
        readinessCoordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: photoOutput)
        
        let delegate = PhotoReadinessCoordinatorDelegate(session: self)
        defer { _ = delegate }
        readinessCoordinator?.delegate = delegate
        #endif
        
        readinessCoordinator?.startTrackingCaptureRequest(using: photoSettings)
        defer { readinessCoordinator?.stopTrackingCaptureRequest(using: photoSettings.uniqueID) }
        return try await action()
    }
    
    private var inFlightPhotoCaptureDelegates: [Int64: PhotoCaptureDelegate] = [:]
}

// MARK: - Setup & Configure

extension PhotoCaptureSession {
    private func _configurePhotoOutput() {
        #if !os(watchOS) && !os(visionOS)
        photoOutput.maxPhotoQualityPrioritization = .quality
        let supportedMaxDimensions = camera.device?.activeFormat.supportedMaxPhotoDimensions
        if let supportedMaxDimensions, !supportedMaxDimensions.isEmpty {
            photoOutput.maxPhotoDimensions = supportedMaxDimensions.last!
        }
        #endif

        #if os(iOS) && !targetEnvironment(macCatalyst)
        if photoOutput.isAutoDeferredPhotoDeliverySupported {
            photoOutput.isAutoDeferredPhotoDeliveryEnabled = captureOptions.contains(.autoDeferredPhotoDelivery)
        }
        #endif
        if photoOutput.isZeroShutterLagSupported {
            photoOutput.isZeroShutterLagEnabled = captureOptions.contains(.zeroShutterLag)
        }
        if photoOutput.isResponsiveCaptureSupported {
            photoOutput.isResponsiveCaptureEnabled = captureOptions.contains(.responsiveCapture)
            if photoOutput.isFastCapturePrioritizationSupported {
                photoOutput.isFastCapturePrioritizationEnabled = captureOptions.contains(.fastCapturePrioritization)
            }
        }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *) {
            if photoOutput.isConstantColorSupported {
                photoOutput.isConstantColorEnabled = captureOptions.contains(.constantColor)
            }
        }
    }
    
    private func _setupFusionCameraIfNecessary() {
        #if os(iOS)
        guard camera.isFusionCamera else { return }
        
        let wideAngleCameraZoomFactor = camera.device?
            .virtualDeviceSwitchOverVideoZoomFactors
            .first
        guard let wideAngleCameraZoomFactor else { return }
        
        withCurrentCaptureDevice { device in
            device.videoZoomFactor = CGFloat(truncating: wideAngleCameraZoomFactor)
        }
        #endif
    }
    
    private func _configurePreviewStabilizationMode() {
        #if os(iOS)
        for connection in captureSession.connections {
            guard connection.videoPreviewLayer != nil else { continue }
            connection.preferredVideoStabilizationMode = .auto
        }
        #endif
    }
    
    fileprivate func _removeInFlightPhotoDelegate(for uniqueID: Int64) {
        inFlightPhotoCaptureDelegates[uniqueID] = nil
    }
}
