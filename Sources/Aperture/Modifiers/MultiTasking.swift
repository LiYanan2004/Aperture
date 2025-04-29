//
//  MultiTasking.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/30.
//

import SwiftUI

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Enable multitasking camera access if the device supports.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func captureWhenMultiTaskingEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.captureWhenMultiTasking = enabled
        }
    }
}
