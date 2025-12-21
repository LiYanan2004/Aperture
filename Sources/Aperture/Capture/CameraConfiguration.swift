//
//  CameraConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import AVFoundation

public struct CameraConfiguration: Hashable, Sendable {
    public var sessionPreset: AVCaptureSession.Preset
    
    public static let photo = CameraConfiguration(
        sessionPreset: .photo
    )
    
    public static let hd1080p = CameraConfiguration(
        sessionPreset: .hd1920x1080
    )
    
    public static let hd4k = CameraConfiguration(
        sessionPreset: .hd4K3840x2160
    )
}
