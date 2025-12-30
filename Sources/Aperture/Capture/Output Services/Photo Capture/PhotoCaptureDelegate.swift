//
//  PhotoCaptureDelegate.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import AVFoundation
import SwiftUI

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, Logging {
    private var continuation: CheckedContinuation<CapturedPhoto, Error>
    private unowned var camera: Camera
    /// Optional customizer used to generate the encoded photo data.
    ///
    /// - Note: This is only used on iOS where `AVCapturePhotoFileDataRepresentationCustomizer` exists.
    ///   On macOS the property is accepted for API consistency but is ignored and `fileDataRepresentation()`
    ///   is used instead.
    let dataRepresentationCustomizer: (any PhotoFileDataRepresentationCustomizer)?
    
    private var capturedPhoto = CapturedPhoto()
    
    init(
        camera: Camera,
        dataRepresentationCustomizer: (any PhotoFileDataRepresentationCustomizer)?,
        continuation: CheckedContinuation<CapturedPhoto, Error>
    ) {
        self.camera = camera
        self.dataRepresentationCustomizer = dataRepresentationCustomizer
        self.continuation = continuation
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        #if os(iOS)
        if !resolvedSettings.livePhotoMovieDimensions.isZero {
            Task { @MainActor in
                camera.inProgressLivePhotoCount += 1
            }
        }
        #endif
        
        // Fully dim the preview and show it back.
        camera.previewDimming = true
        withAnimation(.smooth(duration: 0.25)) {
            camera.previewDimming = false
        }
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            logger.error("There is an error when finishing processing photo: \(error.localizedDescription)")
            return
        }
        
        let photoData: Data?
        #if os(iOS)
        photoData = if let dataRepresentationCustomizer {
            photo.fileDataRepresentation(with: dataRepresentationCustomizer)
        } else {
            photo.fileDataRepresentation()
        }
        #else
        photoData = photo.fileDataRepresentation()
        #endif
        
        guard let photoData else {
            logger.warning("AVCapturePhoto does not produce any data.")
            return
        }
        
        var representation: CapturedPhoto.Representation?
        
        #if os(iOS)
        if photo.isRawPhoto {
            representation = .appleProRAW
        }
        #endif

        if #available(iOS 18.0, macOS 15.0, *), photo.isConstantColorFallbackPhoto {
            representation = .constantColorFallback
        }

        capturedPhoto.addPhotoData(photoData, for: representation ?? .processed)
    }
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL,
        resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        Task { @MainActor in
            camera.inProgressLivePhotoCount -= 1
        }
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
        duration: CMTime,
        photoDisplayTime: CMTime,
        resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        if let error {
            logger.debug("Error processing Live Photo companion movie: \(String(describing: error))")
        }
        capturedPhoto.livePhotoMovieURL = outputFileURL
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?,
        error: Error?
    ) {
        if let error {
            logger.error("There is an error when finishing capturing deferred photo: \(error.localizedDescription)")
            return
        }
        
        let proxyData = if let dataRepresentationCustomizer {
            deferredPhotoProxy?.fileDataRepresentation(with: dataRepresentationCustomizer)
        } else {
            deferredPhotoProxy?.fileDataRepresentation()
        }
        guard let proxyData else {
            logger.warning("AVCaptureDeferredPhotoProxy does not produce any data.")
            return
        }
        capturedPhoto.addPhotoData(proxyData, for: .proxy)
    }
    #endif

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        if let error {
            logger.error("There is an error when finishing processing photo: \(error.localizedDescription)")
        }
        
        guard capturedPhoto.isValid else {
            continuation.resume(throwing: PhotoCaptureError.noPhotoData)
            return
        }
        
        continuation.resume(
            returning: capturedPhoto
        )
    }
}

enum PhotoCaptureError: Error {
    case noPhotoData
}

// MARK: - Auxiliary

fileprivate extension CMVideoDimensions {
    var isZero: Bool {
        width == 0 && height == 0
    }
}
