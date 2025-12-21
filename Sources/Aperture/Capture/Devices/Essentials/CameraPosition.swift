//
//  CameraPosition.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/9.
//

import AVFoundation

/// Constants that indicate the physical position of a capture device.
public enum CameraPosition: Sendable, Hashable {
    case front
    @available(macOS, unavailable)
    case back
    
    public static var platformDefault: Self {
        #if os(macOS) || targetEnvironment(macCatalyst)
        .front
        #else
        .back
        #endif
    }
    
    /// Equal representation of this value to `AVCaptureDevice.Position`.
    var _avCaptureDevicePosition: AVCaptureDevice.Position {
        switch self {
            case .front: .front
            case .back: .back
        }
    }
    
    @available(macOS, unavailable)
    mutating func toggle() {
        self = self == .front ? .back : .front
    }
}

