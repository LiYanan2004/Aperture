//
//  ConstantColor.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Prefer capture content in constant color if the device is capable.
    ///
    /// - note: If flash mode is off, constant color will be disabled even if the device is capable.
    @available(iOS 18.0, tvOS 18.0, macOS 15.0, *)
    public func cameraConstantColorEnabled(_ enabled: Bool = true, fallbackDeliveryEnabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferConstantColor = enabled
            configuration.enableConstantColorFallbackDelivery = enabled
        }
    }
}
