//
//  PhotoFileDataRepresentationCustomizer.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/30.
//

import AVFoundation

#if os(iOS)
/// A cross-platform overload of `AVCapturePhotoFileDataRepresentationCustomizer` for customizing `AVCapturePhoto` file data output.
///
/// For more information, check out the documentation from [Apple Developer Website](https://developer.apple.com/documentation/avfoundation/avcapturephotofiledatarepresentationcustomizer).
public protocol PhotoFileDataRepresentationCustomizer: AVCapturePhotoFileDataRepresentationCustomizer {
}
#else
/// A cross-platform overload of `AVCapturePhotoFileDataRepresentationCustomizer` for customizing `AVCapturePhoto` file data output.
///
/// For more information, check out the documentation from [Apple Developer Website](https://developer.apple.com/documentation/avfoundation/avcapturephotofiledatarepresentationcustomizer).
public protocol PhotoFileDataRepresentationCustomizer {
}
#endif
