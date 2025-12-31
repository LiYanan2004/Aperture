//
//  TelephotoCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/28.
//

import AVFoundation

/// A built-in telephoto rear camera.
@available(macOS, unavailable)
public struct TelephotoCamera: SemanticCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition? = .back

    /// Creates a telephoto rear camera.
    public init() {
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        ).devices.first
    }
}

@available(macOS, unavailable)
extension SemanticCamera where Self == TelephotoCamera {
    /// Telephoto rear camera.
    public static var telephotoCamera: TelephotoCamera {
        .init()
    }
}
