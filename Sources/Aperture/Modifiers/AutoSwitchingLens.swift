//
//  AutoSwitchingLens.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Enable auto lens switching behavior when capture device consists of multiple lens.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    func autoSwitchingLensEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoSwitchingLens = enabled
        }
    }
}
