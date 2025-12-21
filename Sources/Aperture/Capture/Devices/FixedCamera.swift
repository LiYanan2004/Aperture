//
//  FixedCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

public struct FixedCamera: CameraDevice {
    public var device: AVCaptureDevice?
    public var position: CameraPosition
    
    public init(
        deviceType: CameraDeviceType,
        position: CameraPosition = .platformDefault
    ) {
        self.position = position
        self.device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [deviceType._avCaptureDeviceDeviceType],
            mediaType: .video,
            position: position._avCaptureDevicePosition
        ).devices.first
    }
}

extension CameraDevice where Self == FixedCamera {
    public static func fixed(deviceType: CameraDeviceType, position: CameraPosition) -> FixedCamera {
        .init(deviceType: deviceType, position: position)
    }
}
