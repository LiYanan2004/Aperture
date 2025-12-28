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
///
/// This type is designed to be lightweight, sendable across concurrency domains, and suitable for use as a stable identifier or cache key.
public struct CapturedPhoto: Sendable, Hashable {
    /// The primary image data produced by the capture.
    public var data: Data

    /// A fallback photo for capturing with constant color mode.
    public var constantColorFallbackPhotoData: Data?

    /// A Boolean value indicating whether ``data`` is a proxy representation.
    ///
    /// For photo proxy, you will need to use `PhotoKit` to process it:
    ///
    /// ```swift
    /// PHAssetCreationRequest.forAsset().addResource(with: .photoProxy, data: data, options: nil)
    /// ```
    public let isProxy: Bool

    /// The file URL of the associated Live Photo movie, if available.
    public let livePhotoMovieURL: URL?

    /// A Boolean value indicating whether captured photo is a Live Photo.
    public var isLivePhoto: Bool { livePhotoMovieURL != nil }
}
