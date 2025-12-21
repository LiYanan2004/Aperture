//
//  PhotoCaptureDelegate.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import AVFoundation
import OSLog
import SwiftUI

@available(visionOS, unavailable)
@available(watchOS, unavailable)
final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, Logging {
    private var continuation: CheckedContinuation<CapturedPhoto, Never>
    private unowned var camera: Camera
    
    init(
        camera: Camera,
        continuation: CheckedContinuation<CapturedPhoto, Never>
    ) {
        self.camera = camera
        self.continuation = continuation
    }
    
    private var capturedPhoto: CapturedPhoto? {
        willSet {
            guard let newValue else { return }
            continuation.resume(returning: newValue)
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        // Fully dim the preview and show it back.
        camera.previewDimming = true
        withAnimation(.smooth(duration: 0.25)) {
            camera.previewDimming = false
        }
    }

    #if !os(visionOS)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            logger.error("There is an error when finishing processing photo: \(error.localizedDescription)")
            return
        }
        
        capturedPhoto = .photo(photo)
    }
    #endif
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error = error {
            logger.error("There is an error when finishing capturing deferred photo: \(error.localizedDescription)")
            return
        }
        
        if let deferredPhotoProxy {
            capturedPhoto = .photo(deferredPhotoProxy)
        }
    }
    #endif
}
