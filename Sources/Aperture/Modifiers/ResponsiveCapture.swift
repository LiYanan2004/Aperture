//
//  ResponsiveCapture.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Enable responsive capture if the device supports.
    ///
    /// Zero shutter lag will be automatically enabled if you enable responsive capture.
    ///
    /// - parameter fastCapturePrioritized: A Boolean value that indicates whether the output enables fast capture prioritization.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func responsiveCaptureEnabled(
        _ enabled: Bool = true,
        fastCapturePrioritized: Bool = true
    ) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferResponsiveCapture = enabled
            if enabled {
                configuration.preferZeroShutterLag = true
                configuration.preferFastCapturePrioritization = fastCapturePrioritized
            }
        }
    }
}
