//
//  BuiltInCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/31.
//

import AVFoundation

/// A built-in camera that consists of multiple available lens (if available), or single wide angle camera.
public struct BuiltInCamera: SemanticCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition?
    
    /// Creates an instance for the given position.
    public init(position: CameraPosition = .platformDefault) {
        self.position = position
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: BuiltInCamera.supportedDeviceTypes,
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

extension SemanticCamera where Self == BuiltInCamera {
    /// A built-in camera for the default device position.
    @_transparent
    public static var builtInCamera: BuiltInCamera {
        #if os(iOS)
        builtInRearCamera
        #else
        builtInFrontCamera
        #endif
    }
    
    /// A built-in camera for a specific device position.
    public static func builtInCamera(position: CameraPosition) -> BuiltInCamera {
        .init(position: position)
    }
    
    /// A front camera of the current device.
    public static var builtInFrontCamera: BuiltInCamera {
        .init(position: .front)
    }
    
    /// A rear camera of the current device.
    @available(macOS, unavailable)
    public static var builtInRearCamera: BuiltInCamera {
        .init(position: .back)
    }
    
    /// A rear camera of the current device.
    @_transparent
    @available(*, deprecated, renamed: "builtInRearCamera")
    @available(macOS, unavailable)
    public static var builtInBackCamera: BuiltInCamera {
        builtInRearCamera
    }
}
