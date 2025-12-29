//
//  AutomaticCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

/// A built-in camera that consists of multiple available lens (if available), or single wide angle camera.
public struct AutomaticCamera: BuiltInCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition
    
    /// Creates an instance for the given position.
    public init(position: CameraPosition = .platformDefault) {
        self.position = position
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: AutomaticCamera.supportedDeviceTypes,
            mediaType: .video,
            position: AVCaptureDevice.Position(position: position)
        ).devices.first
    }
    
    #if os(macOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
    #elseif os(iOS)
    private static let supportedDeviceTypes = [AVCaptureDevice.DeviceType.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera]
    #endif
}

extension CameraDevice where Self == AutomaticCamera {
    /// An automatic camera for the default device position.
    @_transparent
    public static var automatic: AutomaticCamera {
        #if os(iOS)
        rearCamera
        #else
        frontCamera
        #endif
    }
    
    /// An automatic camera for a specific device position.
    public static func automatic(position: CameraPosition) -> AutomaticCamera {
        .init(position: position)
    }
    
    /// A front camera of the current device.
    public static var frontCamera: AutomaticCamera {
        .init(position: .front)
    }
    
    /// A rear camera of the current device.
    @available(macOS, unavailable)
    public static var rearCamera: AutomaticCamera {
        .init(position: .back)
    }
    
    /// A rear camera of the current device.
    @_transparent
    @available(*, deprecated, renamed: "rearCamera")
    @available(macOS, unavailable)
    public static var backCamera: AutomaticCamera {
        rearCamera
    }
}
