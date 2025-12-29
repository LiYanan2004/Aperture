//
//  ExternalCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

/// An external or continuity camera device.
public struct ExternalCamera: CameraDevice {
    /// Creates an external camera device.
    public init() {
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: Self.supportedDeviceTypes,
            mediaType: .video,
            position: .unspecified
        ).devices.first
    }
    
    public let captureDevice: AVCaptureDevice?
    
    #if os(macOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.external, .continuityCamera, .deskViewCamera]
    #elseif os(iOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.external, .continuityCamera]
    #endif
}

extension CameraDevice where Self == ExternalCamera {
    /// An external camera device.
    ///
    /// On macOS, this could be continuity canera, desk view camera, etc.
    ///
    /// On iPadOS, this could be external camera connected via USB-C port.
    public static var external: ExternalCamera { .init() }
}
