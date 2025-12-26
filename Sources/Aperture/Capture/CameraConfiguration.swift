//
//  CameraConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import AVFoundation

public struct CameraConfiguration: Sendable {
    public var sessionPreset: AVCaptureSession.Preset
    public var services: [any OutputService]
    
    public var photoCaptureService: PhotoCaptureService? {
        services.first(byUnwrapping: { $0 as? PhotoCaptureService })
    }
    
    public var movieCaptureService: MovieCaptureService? {
        services.first(byUnwrapping: { $0 as? MovieCaptureService })
    }
    
    public init(sessionPreset: AVCaptureSession.Preset, @OutputServiceBuilder servicesBuilder: () -> [any OutputService]) {
        self.sessionPreset = sessionPreset
        self.services = servicesBuilder()
    }
    
    public init(sessionPreset: AVCaptureSession.Preset, services: [any OutputService]) {
        self.sessionPreset = sessionPreset
        self.services = services
    }

    public static func == (lhs: CameraConfiguration, rhs: CameraConfiguration) -> Bool {
        lhs.services.map({ $0.eraseToAnyEquatable() }) == rhs.services.map({ $0.eraseToAnyEquatable() }) &&
        lhs.sessionPreset == rhs.sessionPreset
    }
}

// MARK: - Supplementary

extension CameraConfiguration {
    public static let photo = CameraConfiguration(
        sessionPreset: .photo,
        services: [PhotoCaptureService()]
    )
    
    private static let hd1080p = CameraConfiguration(
        sessionPreset: .hd1920x1080,
        services: [MovieCaptureService()]
    )
    
    private static let hd4k = CameraConfiguration(
        sessionPreset: .hd4K3840x2160,
        services: [MovieCaptureService()]
    )
}
