//
//  CaptureQualityPrioritization.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI
import AVFoundation

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Set quality prioritization for output photos.
    ///
    /// Default value is `.balanced`.
    ///
    /// The better quality prioritization means it takes more time to process the photo.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func captureQualityPrioritization(_ prioritization: AVCapturePhotoOutput.QualityPrioritization) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if !os(watchOS) && !os(visionOS)
            configuration.preferedQualityPrioritization = prioritization
            #endif
        }
    }
}
