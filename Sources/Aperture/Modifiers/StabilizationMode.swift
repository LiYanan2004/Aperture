//
//  StabilizationMode.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI
import AVFoundation

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Sets prefered camera stabilization mode.
    @available(macOS, unavailable)
    @available(iOS 17.0, tvOS 17.0, *)
    public func cameraStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if os(iOS) || os(tvOS)
            configuration.stabilizationMode = mode
            #endif
        }
    }
}
