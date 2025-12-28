//
//  UltraWideAngleCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/28.
//

import AVFoundation

public struct UltraWideAngleCamera: BuiltInCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition = .back

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
    public static var ultraWideAngleCamera: UltraWideAngleCamera {
        .init()
    }
}
