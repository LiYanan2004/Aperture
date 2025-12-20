//
//  CaptureConfiguration.CameraSettings.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/9.
//

import AVFoundation
import SwiftUI

extension CaptureConfiguration {
    struct CameraSettings: Hashable, Sendable {
        var autoLensSwitching = true
        /// Prefered capture device types.
        /// - note: By default, it uses composed device type or wide-angle camera.
        var captureDeviceTypes: [AVCaptureDevice.DeviceType]? = nil
    }
    
    nonisolated public func autoLensSwitchingDisabled(
        _ flag: Bool = true
    ) -> CaptureConfiguration {
        var config = self
        config.cameraSettings.autoLensSwitching = !flag
        return config
    }
}
