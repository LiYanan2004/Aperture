//
//  CaptureConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import SwiftUI
import AVFoundation

public struct CaptureConfiguration: Sendable, Equatable {
    public var captureOptions: CaptureOptions = .default
    public var multiTasking = false
    public var autoLensSwitching = true
    /// Prefered capture device types.
    /// - note: By default, it uses composed device type or wide-angle camera.
    public var captureDeviceTypes: [AVCaptureDevice.DeviceType]? = nil
    #if os(iOS)
    /// Prefered stabilization mode for current capture device.
    var previewStabilizationMode = AVCaptureVideoStabilizationMode.previewOptimized
    #endif
    public var photoSettings = PhotoSettings()
    
    nonisolated public func multiTaskingEnabled(
        _ flag: Bool = true
    ) -> CaptureConfiguration {
        var config = self
        config.multiTasking = flag
        return config
    }
    
    nonisolated public func autoLensSwitchingDisabled(
        _ flag: Bool = true
    ) -> CaptureConfiguration {
        var config = self
        config.autoLensSwitching = !flag
        return config
    }
    
    nonisolated public func captureDeviceTypes(
        _ deviceTypes: [AVCaptureDevice.DeviceType]
    ) -> CaptureConfiguration {
        var config = self
        config.captureDeviceTypes = deviceTypes
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

