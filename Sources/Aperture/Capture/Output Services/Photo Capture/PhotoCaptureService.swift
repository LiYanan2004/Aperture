//
//  PhotoCapture.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/21.
//

@preconcurrency import AVFoundation
import Foundation
import Combine
import OSLog

public struct PhotoCaptureService: OutputService, Logging {
    public let sceneMonitoringPhotoSettings = AVCapturePhotoSettings()
    @Cancellables private var flashSceneObservers: Set<AnyCancellable>
    
    public var captureOptions: RequestedPhotoCaptureOptions = []
    
    public init(
        captureOptions: RequestedPhotoCaptureOptions = []
    ) {
        self.captureOptions = captureOptions
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeOutput(context: Context) -> AVCapturePhotoOutput {
        let output = AVCapturePhotoOutput()
        output.maxPhotoQualityPrioritization = .quality

        #if os(iOS)
        sceneMonitoringPhotoSettings.flashMode = .auto
        output.photoSettingsForSceneMonitoring = sceneMonitoringPhotoSettings
        #endif
        
        return output
    }
    
    public func updateOutput(output: AVCapturePhotoOutput, context: Context) {
        let maxSupportedPhotoDimensions = context.inputDevice
            .activeFormat
            .supportedMaxPhotoDimensions
            .last
        if let maxSupportedPhotoDimensions {
            output.maxPhotoDimensions = maxSupportedPhotoDimensions
        }
        
        #if os(iOS)
        output.isLivePhotoCaptureEnabled = output.isLivePhotoCaptureSupported
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
        
        #if os(iOS)
        flashSceneObservers = []
        withValueObservation(
            of: output,
            keyPath: \.isFlashScene,
            cancellables: &flashSceneObservers
        ) { isFlashScene in
            context.coordinator.setFlashScene(isFlashScene)
        }
        #endif
    }
    
    public final class Coordinator: FlashSceneRecommendationDelegate {
        weak var cameraCoordinator: CameraCoordinator!
        
        func setFlashScene(_ isFlashScene: Bool) {
            Task { @MainActor in
                precondition(cameraCoordinator != nil, "CameraCoordinator must not equal to nil")
                cameraCoordinator?.camera.flash.isFlashRecommendedByScene = isFlashScene
            }
        }
    }
}

extension PhotoCaptureService {
    internal func photoSettings(
        output: Output,
        configuration: PhotoCaptureConfiguration,
        context: Context
    ) async throws -> AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings()
        
        let dimensions = if let minimumPixelCount = configuration.resolution._minimumPixelCount {
            context.inputDevice.activeFormat
                .supportedMaxPhotoDimensions
                .first(where: {
                    $0.width * $0.height > minimumPixelCount
                })
        } else {
            context.inputDevice.activeFormat.supportedMaxPhotoDimensions.last
        }
        guard let dimensions else {
            throw CameraError.unsatisfiablePhotoCaptureConfiguration(key: \.resolution)
        }
        
        photoSettings.maxPhotoDimensions = dimensions
        photoSettings.photoQualityPrioritization = configuration.qualityPrioritization
        #if os(iOS)
        photoSettings.livePhotoMovieFileURL = configuration.capturesLivePhoto ? URL.movieFileURL : nil
        #endif
        
        let flash = await context.coordinator.cameraCoordinator.camera.flash
        if output.supportedFlashModes.contains(flash.userSelectedMode) {
            photoSettings.flashMode = flash.userSelectedMode
        }
        
        @available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *)
        func _enableConstantColorIfRequestedAndEligible() {
            guard captureOptions.contains(.constantColor) else { return }
            guard output.isConstantColorSupported else {
                logger.error("[Constant Color] Current device doesn't support constant color.")
                return
            }
            guard photoSettings.flashMode != .off else {
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
}

protocol FlashSceneRecommendationDelegate {
    func setFlashScene(_ isFlashScene: Bool)
}

// MARK: - Auxiliary

fileprivate extension URL {
    /// A unique output location to write a movie.
    static var movieFileURL: URL {
        URL.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension(for: .quickTimeMovie)
    }
}
