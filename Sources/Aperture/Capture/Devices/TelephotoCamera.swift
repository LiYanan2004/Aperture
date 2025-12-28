//
//  TelephotoCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/28.
//

import AVFoundation

public struct TelephotoCamera: BuiltInCamera {
    public let captureDevice: AVCaptureDevice?
    public let position: CameraPosition = .back

    public init() {
        self.captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        ).devices.first
    }
}

@available(macOS, unavailable)
extension CameraDevice where Self == TelephotoCamera {
    public static var telephotoCamera: TelephotoCamera {
        .init()
    }
}
