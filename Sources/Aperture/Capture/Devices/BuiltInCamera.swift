//
//  BuiltInCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

public struct BuiltInCamera: CameraDevice {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition
    
    public init(
        position: CameraPosition = .platformDefault,
        deviceTypes: [AVCaptureDevice.DeviceType]? = nil
    ) {
        self.position = position
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes ?? Self.supportedDeviceTypes,
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

extension CameraDevice where Self == BuiltInCamera {
    public static var builtInFrontCamera: BuiltInCamera {
        .init(position: .front)
    }
    
    @available(macOS, unavailable)
    public static func builtInRearCamera(usesFusionCamera: Bool = true) -> BuiltInCamera {
        .init(
            position: .back,
            deviceTypes: usesFusionCamera ? nil : [.builtInWideAngleCamera]
        )
    }
    
    @inlinable
    public static func builtInCamera(
        position: CameraPosition = .platformDefault,
        usesFusionCamera: Bool = true
    ) -> BuiltInCamera {
        switch position {
            case .front:
                builtInFrontCamera
            #if !os(macOS)
            case .back:
                builtInRearCamera(usesFusionCamera: usesFusionCamera)
            #endif
        }
    }
}
