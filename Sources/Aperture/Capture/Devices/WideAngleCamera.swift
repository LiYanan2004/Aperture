//
//  WideAngleCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/28.
//

import AVFoundation

public struct WideAngleCamera: BuiltInCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition

    public init(position: CameraPosition = .platformDefault) {
        self.position = position
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: AVCaptureDevice.Position(position: position)
        ).devices.first
    }
}

extension CameraDevice where Self == WideAngleCamera {
    public static func wideAngleCamera(
        position: CameraPosition = .platformDefault
    ) -> WideAngleCamera {
        .init(position: position)
    }
}
