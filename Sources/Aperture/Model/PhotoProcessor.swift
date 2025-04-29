import SwiftUI
@preconcurrency import AVFoundation

/// Constants that indicates the type of captured content along with the content itself.
@available(visionOS, unavailable)
@available(watchOS, unavailable)
public enum CapturedPhoto: Sendable {
    /// A simple photo.
    case photo(AVCapturePhoto)
    #if os(iOS) && !targetEnvironment(macCatalyst)
    /// A proxy photo that defers photo processing.
    case proxyPhoto(AVCaptureDeferredPhotoProxy)
    #endif
    
    /// An `AVCapturePhoto` representation.
    /// - tip: You can unwrap it back to `AVCaptureDeferredPhotoProxy` if the type is `proxyPhoto`.
    public var underlyingPhotoObject: AVCapturePhoto {
        switch self {
        case .photo(let photo): photo
        #if os(iOS) && !targetEnvironment(macCatalyst)
        case .proxyPhoto(let photo): photo
        #endif
        }
    }
    
    /// File representation of this photo.
    public var dataRepresentation: Data? {
        switch self {
        case .photo(let photo): photo.fileDataRepresentation()
        #if os(iOS) && !targetEnvironment(macCatalyst)
        case .proxyPhoto(let photo): photo.fileDataRepresentation()
        #endif
        }
    }
    
    #if canImport(UIKit)
    /// The current photo, rasterized as a UIKit image.
    public var uiimage: UIImage? {
        if let dataRepresentation {
            return UIImage(data: dataRepresentation)
        }
        return nil
    }
    #elseif canImport(AppKit)
    /// The current photo, rasterized as a AppKit image.
    public var nsimage: NSImage? {
        if let dataRepresentation {
            return NSImage(data: dataRepresentation)
        }
        return nil
    }
    #endif
}

@available(visionOS, unavailable)
@available(watchOS, unavailable)
final class PhotoProcessor: NSObject, AVCapturePhotoCaptureDelegate {
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
            camera?.logger.error("There is an error when finishing processing photo: \(error.localizedDescription)")
            camera?.errorHandler?(.captureError(error))
            return
        }
        
        capturedPhoto = .photo(photo)
    }
    #endif
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error = error {
            camera?.logger.error("There is an error when finishing capturing deferred photo: \(error.localizedDescription)")
            camera?.errorHandler?(.captureError(error))
            return
        }
        
        if let deferredPhotoProxy {
            capturedPhoto = .photo(deferredPhotoProxy)
        }
    }
    #endif
}
