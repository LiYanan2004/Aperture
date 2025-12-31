//
//  ContinuityCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/30.
//

import AVFoundation

/// A camera device that represents a Continuity Camera source.
public struct ContinuityCamera: SemanticCamera {
    public let captureDevice: AVCaptureDevice?
    
    fileprivate init(device: AVCaptureDevice?) {
        self.captureDevice = device
    }
    
    public static var availableCameras: [ContinuityCamera] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.continuityCamera],
            mediaType: .video,
            position: .unspecified
        ).devices.map { ContinuityCamera(device: $0) }
    }
}

extension SemanticCamera where Self == ContinuityCamera {
    /// A list of Continuity Camera devices currently available on the system.
    public static var continuityCameras: [ContinuityCamera] {
        ContinuityCamera.availableCameras
    }
}
