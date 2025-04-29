import SwiftUI
import OSLog
@preconcurrency import AVFoundation

@available(visionOS, unavailable)
@available(watchOS, unavailable)
final class PhotoProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let logger = Logger(subsystem: "Aperture", category: "PhotoProcessor")
    
    private var continuation: CheckedContinuation<CapturedPhoto, Never>!
    private weak var camera: Camera?
    private var capturedPhoto: CapturedPhoto? {
        willSet {
            guard let newValue else { return }
            continuation.resume(returning: newValue)
        }
    }
    
    func setup(continuation: CheckedContinuation<CapturedPhoto, Never>, camera: Camera) {
        self.continuation = continuation
        self.camera = camera
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Fully dim the preview and show it back.
        camera?.dimCameraPreview = 1
        withAnimation(.smooth(duration: 0.25)) {
            camera?.dimCameraPreview = 0
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
