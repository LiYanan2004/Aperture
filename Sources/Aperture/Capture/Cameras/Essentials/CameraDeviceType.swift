//
//  CameraDeviceType.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation

public enum CameraDeviceType: Hashable, Sendable {
    case wideAngleCamera
    @available(macOS, unavailable)
    case telephotoCamera
    @available(macOS, unavailable)
    case ultraWideCamera
    @available(iOS, unavailable)
    case deskViewCamera
    case continuityCamera
    
    package var _avCaptureDeviceDeviceType: AVCaptureDevice.DeviceType {
        switch self {
            case .wideAngleCamera: .builtInWideAngleCamera
            #if os(iOS)
            case .telephotoCamera: .builtInTelephotoCamera
            case .ultraWideCamera: .builtInUltraWideCamera
            #else
            case .deskViewCamera: .deskViewCamera
            #endif
            case .continuityCamera: .continuityCamera
        }
    }
}
