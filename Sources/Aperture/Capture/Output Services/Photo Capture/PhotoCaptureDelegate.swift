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
    
    private var photoData: Data?
    private var constantColorFallbackPhotoData: Data?
    private var isProxy: Bool = false
    private var livePhotoMovieURL: URL?
    
    init(
        camera: Camera,
        continuation: CheckedContinuation<CapturedPhoto, Error>
    ) {
        self.camera = camera
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
        }
        
        let photoData = photo.fileDataRepresentation()
        if #available(iOS 18.0, macOS 15.0, *),
           photo.isConstantColorFallbackPhoto {
            self.constantColorFallbackPhotoData = photoData
        } else {
            self.photoData = photoData
        }
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
        livePhotoMovieURL = outputFileURL
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?,
        error: Error?
    ) {
        if let error = error {
            logger.error("There is an error when finishing capturing deferred photo: \(error.localizedDescription)")
            return
        }
        
        photoData = deferredPhotoProxy?.fileDataRepresentation()
        isProxy = true
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
        
        guard let photoData else {
            continuation.resume(throwing: PhotoCaptureError.noPhotoData)
            return
        }
        
        continuation.resume(
            returning: CapturedPhoto(
                data: photoData,
                constantColorFallbackPhotoData: constantColorFallbackPhotoData,
                isProxy: isProxy,
                livePhotoMovieURL: livePhotoMovieURL
            )
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
