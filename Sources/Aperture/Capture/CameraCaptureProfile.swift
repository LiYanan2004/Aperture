//
//  CameraConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import AVFoundation

public struct CameraCaptureProfile: Sendable {
    public var sessionPreset: AVCaptureSession.Preset
    public var outputServices: [any OutputService]
    
    public var photoCaptureService: PhotoCaptureService? {
        outputServices.first(byUnwrapping: { $0 as? PhotoCaptureService })
    }
    
    public var movieCaptureService: MovieCaptureService? {
        outputServices.first(byUnwrapping: { $0 as? MovieCaptureService })
    }
    
    public init(sessionPreset: AVCaptureSession.Preset, @OutputServiceBuilder servicesBuilder: () -> [any OutputService]) {
        self.sessionPreset = sessionPreset
        self.outputServices = servicesBuilder()
    }
    
    public init(sessionPreset: AVCaptureSession.Preset, services: [any OutputService]) {
        self.sessionPreset = sessionPreset
        self.outputServices = services
    }

    public static func == (lhs: CameraCaptureProfile, rhs: CameraCaptureProfile) -> Bool {
        lhs.outputServices.map({ $0.eraseToAnyEquatable() }) == rhs.outputServices.map({ $0.eraseToAnyEquatable() }) &&
        lhs.sessionPreset == rhs.sessionPreset
    }
}

// MARK: - Supplementary

extension CameraCaptureProfile {
    public static let photo = CameraCaptureProfile(
        sessionPreset: .photo,
        services: [PhotoCaptureService()]
    )
    
    private static let hd1080p = CameraCaptureProfile(
        sessionPreset: .hd1920x1080,
        services: [MovieCaptureService()]
    )
    
    private static let hd4k = CameraCaptureProfile(
        sessionPreset: .hd4K3840x2160,
        services: [MovieCaptureService()]
    )
}
