//
//  TransformCameraCaptureConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import SwiftUI

extension View {
    @_spi(Experimental)
    nonisolated public func cameraCaptureConfiguration(
        _ transform: @escaping (_ configuration: CaptureConfiguration) -> CaptureConfiguration
    ) -> some View {
        transformEnvironment(\.captureConfiguration) { configuration in
            configuration = transform(configuration)
        }
    }
}
