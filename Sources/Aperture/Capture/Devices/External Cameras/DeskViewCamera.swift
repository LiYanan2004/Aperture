//
//  DeskViewCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/30.
//

import AVFoundation

/// A camera device that represents a Desk View source.
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
public struct DeskViewCamera: SemanticCamera {
    public let captureDevice: AVCaptureDevice?
    
    fileprivate init(device: AVCaptureDevice?) {
        self.captureDevice = device
    }
    
    public static var availableCameras: [DeskViewCamera] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.deskViewCamera],
            mediaType: .video,
            position: .unspecified
        ).devices.map { DeskViewCamera(device: $0) }
    }
}

@available(iOS, unavailable)
@available(macCatalyst, unavailable)
extension SemanticCamera where Self == DeskViewCamera {
    /// A list of Desk View camera devices currently available on the system.
    public static var deskViewCameras: [DeskViewCamera] {
        DeskViewCamera.availableCameras
    }
}
