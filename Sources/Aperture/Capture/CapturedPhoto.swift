//
//  CapturedPhoto.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/29.
//

@preconcurrency import AVFoundation
import SwiftUI

/// A data representation of current captured photo.
///
/// On iOS, if you enable deferred photo delivery, this would be `.proxyPhoto(AVCaptureDeferredPhotoProxy)`, otherwise, `.photo(AVCapturePhoto)`.
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
    ///
    /// Don't rely on this as it may be removed in the future updates.
    ///
    /// You should retrieve captured photo directly from the enum.
    public var _underlyingPhotoObject: AVCapturePhoto {
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
