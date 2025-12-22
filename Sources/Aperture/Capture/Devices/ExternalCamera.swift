//
//  ExternalCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

public struct ExternalCamera: CameraDevice {
    public let captureDevice: AVCaptureDevice?
    
    public init() {
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: Self.supportedDeviceTypes,
            mediaType: .video,
            position: .unspecified
        ).devices.first
    }
    
    #if os(macOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.external, .continuityCamera, .deskViewCamera]
    #elseif os(iOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.external, .continuityCamera]
    #endif
}

extension CameraDevice where Self == ExternalCamera {
    public static var external: ExternalCamera { .init() }
}
