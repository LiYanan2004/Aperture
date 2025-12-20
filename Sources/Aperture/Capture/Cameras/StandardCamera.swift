//
//  StandardCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

public struct StandardCamera: Camera {
    public var device: AVCaptureDevice?
    public var position: CameraPosition
    
    public init(position: CameraPosition = .platformDefault) {
        self.position = position
        self.device = AVCaptureDevice.DiscoverySession(
            deviceTypes: Self.supportedDeviceTypes,
            mediaType: .video,
            position: position._avCaptureDevicePosition
        ).devices.first
    }
    
    #if os(macOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
    #elseif os(iOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera]
    #endif
}

extension Camera where Self == StandardCamera {
    public static var standard: StandardCamera { .init() }
    
    public static func standard(position: CameraPosition) -> StandardCamera {
        .init(position: position)
    }
}
