//
//  PhotoCaptureService.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/21.
//

@preconcurrency import AVFoundation
import Foundation
import Combine
import OSLog

/// An output service that outputs photo data, including Live Photo.
public struct PhotoCaptureService: OutputService, Logging {
    /// A photo settings specifically configured for scene monitoring.
    ///
    /// This is NOT used when capturing a photo. It's only using for scene monitoring.
    public let sceneMonitoringPhotoSettings = AVCapturePhotoSettings()
    @Cancellables private var flashSceneObservers: Set<AnyCancellable>
    
    /// The option set that is used to configure the output.
    public var options: PhotoCaptureOptions
    
    /// Create an output service that takes photo from connected session.
    public init(options: PhotoCaptureOptions = .default) {
        self.options = options
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
            output.isAutoDeferredPhotoDeliveryEnabled = options.contains(.autoDeferredPhotoDelivery)
        }
        #endif
        if output.isZeroShutterLagSupported {
            output.isZeroShutterLagEnabled = options.contains(.zeroShutterLag)
        }
        if output.isResponsiveCaptureSupported {
            output.isResponsiveCaptureEnabled = options.contains(.responsiveCapture)
            if output.isFastCapturePrioritizationSupported {
                output.isFastCapturePrioritizationEnabled = options.contains(.fastCapturePrioritization)
            }
        }
        #if os(iOS)
        if output.isAppleProRAWSupported {
            output.isAppleProRAWEnabled = options.contains(.appleProRAW)
        } else if options.contains(.appleProRAW) {
            logger.error("[Apple ProRAW] Current device or configuration doesn't support Apple ProRAW.")
        }
        #endif
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, macCatalyst 18.0, *) {
            if output.isConstantColorSupported {
                output.isConstantColorEnabled = options.contains(.constantColor)
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
    internal func createPhotoSettings(
        output: Output,
        configuration: PhotoCaptureConfiguration,
        context: Context
    ) async throws -> AVCapturePhotoSettings {
        let format = processPhotoFormat(for: output, configuration: configuration)
        
        let photoSettings: AVCapturePhotoSettings
        if configuration.dataFormat.includesAppleProRAW,
           let rawPixelFormat = output.availableRawPhotoPixelFormatTypes.first(where: {
               AVCapturePhotoOutput.isAppleProRAWPixelFormat($0)
           }) {
            photoSettings = AVCapturePhotoSettings(
                rawPixelFormatType: rawPixelFormat,
                processedFormat: format
            )
        } else {
            photoSettings = AVCapturePhotoSettings(format: format)
        }
        
        var dimensions: CMVideoDimensions! = context.inputDevice.activeFormat
            .supportedMaxPhotoDimensions
            .first(where: {
                $0.width * $0.height > configuration.preferredResolution._minimumPixelCount
            })
        if dimensions == nil {
            let maximumSupportedPhotoDimensions = context.inputDevice
                .activeFormat
                .supportedMaxPhotoDimensions.last
            precondition(maximumSupportedPhotoDimensions != nil, "Video device must support at least one max photo dimensions.")
            
            logger.warning("Current capture device does not support \(configuration.preferredResolution.description). Fall back to the maximum dimensions supported by the device: \(maximumSupportedPhotoDimensions!.width)x\(maximumSupportedPhotoDimensions!.height)")
            dimensions = maximumSupportedPhotoDimensions!
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
            guard options.contains(.constantColor) else { return }
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

private extension PhotoCaptureService {
    private func processPhotoFormat(
        for output: AVCapturePhotoOutput,
        configuration: PhotoCaptureConfiguration
    ) -> [String : Any]? {
        let availableCodecTypes = output.availablePhotoCodecTypes
        guard !availableCodecTypes.isEmpty else {
            return nil
        }
        
        guard let codec = configuration.dataFormat.codec else {
            return nil
        }
        
        guard availableCodecTypes.contains(codec) else {
            return nil
        }
        
        return [AVVideoCodecKey : codec]
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
