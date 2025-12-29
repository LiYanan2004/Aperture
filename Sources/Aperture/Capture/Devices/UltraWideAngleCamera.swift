//
//  UltraWideAngleCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/28.
//

import AVFoundation

/// A built-in ultra wide rear camera.
@available(macOS, unavailable)
public struct UltraWideAngleCamera: BuiltInCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition = .back

    /// Creates an ultra wide rear camera.
    public init() {
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        ).devices.first
    }
}

@available(macOS, unavailable)
extension CameraDevice where Self == UltraWideAngleCamera {
    /// Ultra wide rear camera.
    public static var ultraWideAngleCamera: UltraWideAngleCamera {
        .init()
    }
}
