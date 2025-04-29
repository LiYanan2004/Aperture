//
//  AutoDeferredPhotoDelivery.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Enable auto deferred photo delivery if the device supports.
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(iOS 17.0, *)
    public func autoDeferredPhotoDeliveryEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferAutoDeferredPhotoDelivery = enabled
        }
    }
}
