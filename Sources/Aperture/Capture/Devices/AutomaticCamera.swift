//
//  AutomaticCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

public struct AutomaticCamera: BuiltInCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition
    
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
    @_transparent
    public static var automatic: AutomaticCamera {
        #if os(iOS)
        rearCamera
        #else
        frontCamera
        #endif
    }
    
    public static func automatic(position: CameraPosition) -> AutomaticCamera {
        .init(position: position)
    }
    
    public static var frontCamera: AutomaticCamera {
        .init(position: .front)
    }
    
    @available(macOS, unavailable)
    public static var rearCamera: AutomaticCamera {
        .init(position: .back)
    }
    
    @_transparent
    @available(*, deprecated, renamed: "rearCamera")
    public static var backCamera: AutomaticCamera {
        rearCamera
    }
}
