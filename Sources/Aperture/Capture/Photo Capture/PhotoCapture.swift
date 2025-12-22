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
        
        let dimensions = if let minimumPixelCount = configuration.resolution._minimumPixelCount {
            device.activeFormat
                .supportedMaxPhotoDimensions
                .first(where: {
                    $0.width * $0.height > minimumPixelCount
                })
        } else {
            device.activeFormat.supportedMaxPhotoDimensions.last
        }
        guard let dimensions else {
            throw CameraError.unsatisfiablePhotoCaptureConfiguration(key: \.resolution)
        }
        
        photoSettings.maxPhotoDimensions = dimensions
        photoSettings.photoQualityPrioritization = configuration.qualityPrioritization
        
        if output.supportedFlashModes.contains(camera.flashMode) {
            photoSettings.flashMode = camera.flashMode
        }
        
        @available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *)
        func _enableConstantColorIfRequestedAndEligible() {
            guard captureOptions.contains(.constantColor) else { return }
            guard output.isConstantColorSupported else {
                logger.error("[Constant Color] Current device doesn't support constant color.")
                return
            }
            guard camera.flashMode != .off else {
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
        var switchOverZoomFactor: CGFloat = 1
        defer {
            Task { @MainActor in
                camera.zoomFactor = switchOverZoomFactor
            }
        }
        
        guard camera.device.isFusionCamera else { return }
        guard let captureDevice = camera.device.captureDevice else { return }
        
        let wideAngleCameraOffset = captureDevice.constituentDevices
            .enumerated()
            .first(where: { $0.element.deviceType == .builtInWideAngleCamera })?
            .offset
        guard let wideAngleCameraOffset else { return }
        
        // "These factors progress in the same order as the devices listed in that property." -- documentation
        // Since switchOverVideoZoomFactor count is N - 1 (where N == constituentDevices.count), shift left by one to remove 1.0x
        let switchOverZoomFactorOffset = wideAngleCameraOffset -  /* 1.0x */ 1
        guard switchOverZoomFactorOffset >= 0 else { return }
        
        switchOverZoomFactor = CGFloat(
            truncating: captureDevice.virtualDeviceSwitchOverVideoZoomFactors[switchOverZoomFactorOffset]
        )
        camera.coordinator.withCurrentCaptureDevice { device in
            device.videoZoomFactor = switchOverZoomFactor
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
