//
//  ExternalCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

/// A camera device that represents an external camera source.
public struct ExternalCamera: SemanticCamera {
    public let captureDevice: AVCaptureDevice?
    
    fileprivate init(device: AVCaptureDevice?) {
        self.captureDevice = device
    }
    
    public static var availableCameras: [ExternalCamera] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external],
            mediaType: .video,
            position: .unspecified
        ).devices.map { ExternalCamera(device: $0) }
    }
}

extension SemanticCamera where Self == ExternalCamera {
    /// A list of external camera devices currently available on the system.
    public static var externalCameras: [ExternalCamera] {
        ExternalCamera.availableCameras
    }
}
