//
//  PhotoCaptureOptions.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import Foundation

/// A set of optional features to request when configuring photo capture.
///
/// These options correspond to optional behaviors in the underlying photo capture pipeline.
///
/// - Important: Setting an option only *requests* the behavior. The system may ignore it depending on the active device, session preset or format, per-capture settings, and runtime conditions.
public struct PhotoCaptureOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Requests zero shutter lag to capture the moment the user intended to capture.
    ///
    /// Zero shutter lag uses a short ring buffer of recent frames so the captured photo can better match the moment the user intended to capture.
    ///
    /// This option is unsupported under these scenarios even when opt-in:
    ///
    /// - Flash photo
    /// - Manual-exposure photo capturing
    /// - Bracket photos
    /// - Constituent photo delivery
    static public let zeroShutterLag = PhotoCaptureOptions(rawValue: 1 << 0)
    /// Requests responsive capture to reduce shot-to-shot latency.
    ///
    /// When enabled, the system may overlap capture and processing so a new capture can begin while a previous capture is still processing.
    ///
    /// - Important: This can improve shot-to-shot time, but increases peak memory usage in the photo output.
    ///
    /// Responsive capture **requires ``PhotoCaptureOptions/zeroShutterLag``**.
    ///
    /// This option may not take effect when the app is under memory pressure, in which case you may prefer (or need) to opt out.
    ///
    /// - SeeAlso: ``PhotoCaptureConfiguration/preferredResolution``
    static public let responsiveCapture = PhotoCaptureOptions(rawValue: 1 << 1)
    /// Prioritizes faster capture performance over quality for responsive capture.
    ///
    /// When enabled, the system can detect multiple captures over a short period of time and adapt photo quality from the highest-quality setting toward a more balanced setting to maintain shot-to-shot time.
    ///
    /// This **requires ``responsiveCapture`` to be enabled**.
    static public let fastCapturePrioritization = PhotoCaptureOptions(rawValue: 1 << 2)
    /// Requests deferred photo delivery to improve shot-to-shot performance.
    ///
    /// When enabled, the system may deliver a lightly processed `AVCaptureDeferredPhotoProxy` at capture time, and finish full-quality processing later.
    ///
    /// Supported on iPhone 11 Pro series, iPhone 12 series or later.
    ///
    /// > note:
    /// > As the name says -- "auto" deferred photo delivery -- the behavior would be automatically determined by `AVFoundation` framework based on active format and device conditions.
    /// >
    /// > As in, even when this is opt-in, the system may still deliver an immediate fully processed photo when a proxy isn’t appropriate (e.g. flash is on, etc.)
    static public let autoDeferredPhotoDelivery = PhotoCaptureOptions(rawValue: 1 << 3)
    /// Requests to use a flash / no-flash pair to reduce the influence of ambient illumination on the output image.
    ///
    /// Based on [WWDC session](https://developer.apple.com/videos/play/wwdc2024/10162/), constant color requires:
    /// - iPhone 14 series or later, iPad Pro (2024) or later
    /// - the flash mode must be set to `.on`or `.auto`
    ///
    /// Constant color isn’t available when capturing RAW photos.
    @available(iOS 18, macOS 15, *)
    static public let constantColor = PhotoCaptureOptions(rawValue: 1 << 4)
    /// Requests Apple ProRAW capture on the photo output.
    ///
    /// Use ``PhotoCaptureConfiguration/dataFormat`` to request RAW-only or RAW+processed delivery per shot.
    ///
    /// - SeeAlso: ``PhotoCaptureConfiguration/dataFormat``
    static public let appleProRAW = PhotoCaptureOptions(rawValue: 1 << 5)
    
    /// Requests depth data and portrait effects matte delivery.
    ///
    /// The system may ignore this option if the active device or format doesn't support depth delivery; when enabled, depth data is embedded in the captured photo and a Portrait Effects Matte is delivered when available.
    static public let deliversDepthData = PhotoCaptureOptions(rawValue: 1 << 6)
}

extension PhotoCaptureOptions {
    /// A set of default enabled options enabled by `AVFoundation` framework.
    ///
    /// Since `Aperture` requires iOS 17 or later, zero shutter lag is enabled when supported by default.
    static public let `default`: PhotoCaptureOptions = [.zeroShutterLag]
    
    /// A set of options that would help reducing shot-to-shot lantency.
    ///
    /// - note: ``autoDeferredPhotoDelivery`` is not included in this set since proxy photo can only be processed via `PhotoKit`.
    static public let prioritizingShotToShotLatency: PhotoCaptureOptions = [
        .zeroShutterLag, .responsiveCapture, .fastCapturePrioritization
    ]
    
    /// A set of options to allow capturing `24MP` photos.
    ///
    /// > Important:
    /// > `24MP` photos will be only delivered as photo proxy and needs post-processing via `PhotoKit`. Under certain conditions (e.g. flash is on), you may still receive a processed photo at `12MP`.
    /// >
    /// > For more guidance on caprturing `24MP` photo, see ``PhotoCaptureConfiguration/preferredResolution``.
    static public let captures24MPPhotos: PhotoCaptureOptions = [
        .autoDeferredPhotoDelivery
    ]
}
