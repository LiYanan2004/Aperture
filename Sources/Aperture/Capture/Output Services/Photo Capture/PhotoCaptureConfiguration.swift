//
//  PhotoCaptureConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/22.
//

import AVFoundation

/// A configuration instance for photo capturing.
public struct PhotoCaptureConfiguration: Hashable, Sendable {
    /// A boolean value indicating whether to capture a live photo.
    public var capturesLivePhoto: Bool = false
    /// Preferred data format of captured photo.
    public var dataFormat: DataFormat = .heif
    /// Preferred output resolution for photo capture.
    ///
    /// The default value is `12MP`. Requesting higher resolutions (such as `24MP` or `48MP`) does not guarantee that the captured photo will match the requested resolution. The actual output depends on the capabilities of the active capture device.
    ///
    /// For example, built-in `1080p` cameras on some Macs will always produce `1080p` images regardless of the requested resolution.
    ///
    /// > Tip:
    /// >
    /// > To enable `24MP` capture on supported devices, make sure to:
    /// > - opt-in ``PhotoCaptureOptions/autoDeferredPhotoDelivery``.
    /// > - set ``qualityPrioritization`` to `.quality`.
    /// >
    /// > **`24MP` photos must be delivered as a photo proxy** and can only be processed by `PhotoKit`.
    /// >
    /// > When you get a photo proxy, get it into the photo library as soon as possible:
    /// >
    /// >  ```swift
    /// >   PHAssetCreationRequest.forAsset().addResource(with: .photoProxy, data: data, options: nil)
    /// > ```
    /// >
    /// > Proxy delivery is evaluated automatically by `AVFoundation` framework and can be suppressed in some capture conditions (for example, when flash is used). In those cases, you will still receive a processed image in `12MP` resolution.
    ///
    /// - SeeAlso: ``configuredFor24MPPhotoCapture()``
    /// - SeeAlso: ``PhotoCaptureService/options``
    /// - SeeAlso: ``PhotoCaptureOptions``
    public var preferredResolution: Resolution = .`12mp`
    /// A settings that indicates how to prioritize photo quality against photo delivery speed.
    public var qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced
    
    /// Create a configuration for photo capturing.
    public init(
        capturesLivePhoto: Bool = false,
        resolution: Resolution = .`12mp`,
        dataFormat: DataFormat = .heif,
        qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced
    ) {
        self.capturesLivePhoto = capturesLivePhoto
        self.dataFormat = dataFormat
        self.preferredResolution = resolution
        self.qualityPrioritization = qualityPrioritization
    }
    
    /// A convenience method to configure 24MP photo capture.
    ///
    /// For more information on `24MP` photo capturing, please refer to ``preferredResolution``.
    public func configuredFor24MPPhotoCapture() -> Self {
        var copy = self
        copy.preferredResolution = .`24mp`
        copy.qualityPrioritization = .quality
        return copy
    }
    
    /// Preferred data format for captured photo.
    public enum DataFormat: Sendable {
        /// Captures photo in HEIF file format.
        case heif
        /// Captures photo in JPEG file format.
        case jpeg
    }
    
    /// Rreferred resolution for photo capture.
    ///
    /// This value expresses a **request**, not a guarantee. The capture pipeline will attempt to
    /// satisfy the requested resolution, but the final output may differ depending on device
    /// capabilities and capture conditions.
    public enum Resolution: Sendable, Hashable, CustomStringConvertible {
        case `48mp`
        case `24mp`
        case `12mp`
        
        public var description: String {
            switch self {
                case .`48mp`: "48MP"
                case .`24mp`: "24MP"
                case .`12mp`: "12MP"
            }
        }
        var _minimumPixelCount: Int32 {
            switch self {
                case .`48mp`: 48_000_000
                case .`24mp`: 24_000_000
                case .`12mp`: 12_000_000
            }
        }
    }
}
