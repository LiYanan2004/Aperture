//
//  CapturedPhoto.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/29.
//

import AVFoundation

/// A value type that represents the result of a photo capture operation.
///
/// `CapturedPhoto` encapsulates the raw image data produced by the camera, along with any associated metadata or auxiliary resources, such as a Live Photo movie. It also carries contextual information describing how the photo was captured.
public struct CapturedPhoto: Sendable, Hashable {
    /// A container for all photo data variants delivered by the capture pipeline.
    var dataProvider: PhotoDataProvider = .init()
    
    /// A `Boolean` value indicates whether this provider is valid or not.
    public var isValid: Bool { _primaryPhotoData != nil }
    
    private var _primaryPhotoData: Data? {
        data(for: .processed) ?? data(for: .proxy) ?? data(for: .appleProRAW)
    }
    /// The primary photo data for this capture.
    ///
    /// The primary representation is selected using a fixed priority order:
    /// - a processed image
    /// - a photo proxy
    /// - an Apple ProRAW representation
    ///
    /// You can still access other kinds of photo data (e.g. constant color fallback photo, processed photo comes with RAW photo, etc.) via ``data(for:)`` based on your needs.
    public var primaryPhotoData: Data {
        precondition(isValid, "\(Self.self) is invalid.")
        return _primaryPhotoData!
    }

    /// Returns the photo data for a given kind, if present.
    public func data(for kind: Representation) -> Data? {
        dataProvider._storage[kind]
    }
    
    /// Returns a `Boolean` value indicates whether the representation is available in the storage.
    public func hasRepresentation(_ representation: Representation) -> Bool {
        dataProvider._storage.keys.contains(representation)
    }

    /// A `Boolean` value indicating whether this object is a proxy representation.
    ///
    /// If this value is true, get it into the photo library as soon as possible:
    ///
    /// ```swift
    /// PHAssetCreationRequest.forAsset().addResource(with: .photoProxy, data: data, options: nil)
    /// ```
    public var isProxy: Bool {
        hasRepresentation(.proxy)
    }

    /// The file URL of the associated Live Photo movie, if available.
    public var livePhotoMovieURL: URL?

    /// A Boolean value indicating whether captured photo is a Live Photo.
    public var isLivePhoto: Bool { livePhotoMovieURL != nil }
    
    internal init() { }
}

extension CapturedPhoto {
    internal mutating func addPhotoData(
        _ data: Data,
        for representation: Representation
    ) {
        dataProvider._storage[representation] = data
    }
    
    /// A value type that holds all photo data variants delivered for a single capture.
    ///
    /// Some capture configurations yield multiple outputs for one shutter press:
    /// - Constant color mode: a primary image plus a fallback image.
    /// - ProRAW with processed companion: a processed image plus a RAW DNG.
    public struct PhotoDataProvider: Sendable, Hashable {
        fileprivate var _storage: [Representation : Data] = [:]
        
        internal init() { }
    }
    
    /// Describes a concrete representation of photo data produced by a single capture.
    public enum Representation: Sendable, Hashable {
        /// A processed image, HEIF or JPEG based on your configuration.
        case processed

        /// An Apple ProRAW representation.
        case appleProRAW

        /// A constant color mode fallback image.
        case constantColorFallback
        
        /// A photo proxy that requires to use `PhotoKit` to do post-processing.
        case proxy
    }
}
