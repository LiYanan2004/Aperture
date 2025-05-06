//
//  TransformCameraCaptureConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import SwiftUI

extension View {
    nonisolated public func transformCameraCaptureConfiguration(
        _ transform: @escaping (inout CaptureConfiguration) -> Void
    ) -> some View {
        transformEnvironment(\.captureConfiguration) { configuration in
            transform(&configuration)
        }
    }
    
    @_spi(Experimental)
    nonisolated public func cameraCaptureConfiguration(
        _ transform: @escaping (CaptureConfiguration) -> CaptureConfiguration
    ) -> some View {
        transformEnvironment(\.captureConfiguration) { configuration in
            configuration = transform(configuration)
        }
    }
}
