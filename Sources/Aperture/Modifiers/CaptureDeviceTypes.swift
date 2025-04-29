//
//  CaptureDeviceTypes.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI
import AVFoundation

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Sets the device types for the camera session to find the appropriate capture device.
    ///
    /// On iOS, it uses a virtual device which consists of all physical lenses.
    ///
    /// On macOS, it uses wide-angle camera and continuity cameras.
    ///
    /// If you want to use a specific lens, you can use this modifier to configure the right lens.
    ///
    /// - note: Be sure to contain `.builtInWideAngleCamera` as a fallback camera.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func captureDeviceTypes(_ deviceTypes: AVCaptureDevice.DeviceType...) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if !os(watchOS) && !os(visionOS)
            configuration.captureDeviceTypes = deviceTypes
            #endif
        }
    }
}
