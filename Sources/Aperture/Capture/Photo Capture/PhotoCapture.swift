//
//  PhotoCapture.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/21.
//

import AVFoundation
import Foundation

public protocol PhotoCaptureOutput: CaptureOutput where Output == AVCapturePhotoOutput {
    func takePhoto(from camera: Camera, configuration: PhotoCaptureConfiguration) async throws -> CapturedPhoto
}

public final class PhotoCapture: PhotoCaptureOutput, Logging {
    public let output = AVCapturePhotoOutput()
    public var captureOptions: RequestedPhotoCaptureOptions = []
    private var inFlightPhotoCaptureDelegates: [Int64: PhotoCaptureDelegate] = [:]
    
    public init() {
        
    }
    
    nonisolated public func takePhoto(
        from camera: Camera,
        configuration: PhotoCaptureConfiguration = .init()
    ) async throws -> CapturedPhoto {
        let photoSettings = try await photoSettings(camera: camera, configuration: configuration)
        
        let capturedPhoto = await withPhotoOutputReadinessCoordinatorTracking(
            camera: camera,
            photoSettings: photoSettings
        ) {
            await withCheckedContinuation { continuation in
                let delegate = PhotoCaptureDelegate(
                    camera: camera,
                    continuation: continuation
                )
                inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = delegate

                output.capturePhoto(with: photoSettings, delegate: delegate)
            }
        }
        
        inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = nil
        
        return capturedPhoto
    }

    nonisolated public func photoSettings(
        camera: Camera,
        configuration: PhotoCaptureConfiguration
    ) async throws -> AVCapturePhotoSettings {
        let device = await camera.coordinator.cameraInputDevice
        guard let device else { throw CameraError.invalidCaptureDevice }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.maxPhotoDimensions = self.output.maxPhotoDimensions
        photoSettings.photoQualityPrioritization = configuration.qualityPrioritization
        
        if output.supportedFlashModes.contains(device.flashMode) {
            photoSettings.flashMode = device.flashMode
        }
        
        @available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *)
        func _enableConstantColorIfRequestedAndEligible() {
            guard captureOptions.contains(.constantColor) else { return }
            guard output.isConstantColorSupported else {
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
    
    @CameraActor
    private func withPhotoOutputReadinessCoordinatorTracking<T>(
        camera: Camera,
        photoSettings: AVCapturePhotoSettings,
        perform action: () async throws -> T
    ) async rethrows -> T {
        var readinessCoordinator: AVCapturePhotoOutputReadinessCoordinator?
        #if os(iOS)
        readinessCoordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: output)
        
        let delegate = PhotoReadinessCoordinatorDelegate(camera: camera)
        defer { _ = delegate }
        readinessCoordinator?.delegate = delegate
        #endif
        
        readinessCoordinator?.startTrackingCaptureRequest(using: photoSettings)
        defer { readinessCoordinator?.stopTrackingCaptureRequest(using: photoSettings.uniqueID) }
        return try await action()
    }
    
    @CameraActor
    public func updateOutput(_ camera: Camera) throws {
        _setupFusionCameraIfNecessary(camera)
        _configurePreviewStabilizationMode(camera)
        try _configurePhotoOutput(camera)
    }
}

extension PhotoCapture {
    @CameraActor
    private func _configurePhotoOutput(_ camera: Camera) throws {
        
        #if !os(watchOS) && !os(visionOS)
        output.maxPhotoQualityPrioritization = .quality
        let supportedMaxDimensions = camera.coordinator.cameraInputDevice?
            .activeFormat
            .supportedMaxPhotoDimensions
        if let supportedMaxDimensions, !supportedMaxDimensions.isEmpty {
            output.maxPhotoDimensions = supportedMaxDimensions.last!
        }
        #endif

        #if os(iOS) && !targetEnvironment(macCatalyst)
        if output.isAutoDeferredPhotoDeliverySupported {
            output.isAutoDeferredPhotoDeliveryEnabled = captureOptions.contains(.autoDeferredPhotoDelivery)
        }
        #endif
        if output.isZeroShutterLagSupported {
            output.isZeroShutterLagEnabled = captureOptions.contains(.zeroShutterLag)
        }
        if output.isResponsiveCaptureSupported {
            output.isResponsiveCaptureEnabled = captureOptions.contains(.responsiveCapture)
            if output.isFastCapturePrioritizationSupported {
                output.isFastCapturePrioritizationEnabled = captureOptions.contains(.fastCapturePrioritization)
            }
        }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *) {
            if output.isConstantColorSupported {
                output.isConstantColorEnabled = captureOptions.contains(.constantColor)
            }
        }
    }
    
    @CameraActor
    private func _setupFusionCameraIfNecessary(_ camera: Camera) {
        #if os(iOS)
        guard camera.device.isFusionCamera else { return }
        
        let wideAngleCameraZoomFactor = camera.device.device?
            .virtualDeviceSwitchOverVideoZoomFactors
            .first
        guard let wideAngleCameraZoomFactor else { return }
        
        camera.coordinator.withCurrentCaptureDevice { device in
            device.videoZoomFactor = CGFloat(truncating: wideAngleCameraZoomFactor)
        }
        #endif
    }
    
    @CameraActor
    private func _configurePreviewStabilizationMode(_ camera: Camera) {
        #if os(iOS)
        for connection in camera.coordinator.captureSession.connections {
            guard connection.videoPreviewLayer != nil else { continue }
            connection.preferredVideoStabilizationMode = .auto
        }
        #endif
    }
    
    fileprivate func _removeInFlightPhotoDelegate(for uniqueID: Int64) {
        inFlightPhotoCaptureDelegates[uniqueID] = nil
    }
}
