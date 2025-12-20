//
//  CaptureConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import SwiftUI
import AVFoundation

public struct CaptureConfiguration: Sendable, Equatable {
    var multiTasking = false
    var cameraSettings = CameraSettings()
    var preferredCaptureOptions: CaptureOptions = []

    #if os(iOS)
    /// Prefered stabilization mode for current capture device.
    var previewStabilizationMode = AVCaptureVideoStabilizationMode.previewOptimized
    #endif
    var photoSettings = PhotoSettings()
    
    func wantsCaptureOptions(_ options: CaptureOptions) -> Bool {
        preferredCaptureOptions.contains(options)
    }
    
    nonisolated public func multiTaskingEnabled(
        _ flag: Bool = true
    ) -> CaptureConfiguration {
        var config = self
        config.multiTasking = flag
        return config
    }
}

// MARK: - Environment Key

/// Camera capture configuration for CameraModel to configure the session.
struct CaptureConfigurationEnvironmentKey: EnvironmentKey {
    static var defaultValue = CaptureConfiguration()
}

extension EnvironmentValues {
    /// The environment value for modifiers to update the configurations.
    package var captureConfiguration: CaptureConfiguration {
        get { self[CaptureConfigurationEnvironmentKey.self] }
        set { self[CaptureConfigurationEnvironmentKey.self] = newValue }
    }
}

