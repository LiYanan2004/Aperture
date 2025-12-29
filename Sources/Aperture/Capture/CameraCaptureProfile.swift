//
//  CameraCaptureProfile.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import AVFoundation

/// A configuation that describes how a camera capture session should be setup.
public struct CameraCaptureProfile: Sendable {
    /// The capture session preset that determines the resolution and overall capture quality.
    public var sessionPreset: AVCaptureSession.Preset
    
    /// The output services enabled for this capture profile.
    public var outputServices: [any OutputService]
    
    /// The photo capture service.
    public var photoCaptureService: PhotoCaptureService? {
        outputServices.first(byUnwrapping: { $0 as? PhotoCaptureService })
    }
    
    /// The movie capture service.
    private var movieCaptureService: MovieCaptureService? {
        outputServices.first(byUnwrapping: { $0 as? MovieCaptureService })
    }
    
    /// Creates a capture profile.
    ///
    /// - Parameters:
    ///   - sessionPreset: The capture session preset to use.
    ///   - servicesBuilder: A result builder that produces the output services associated with this profile.
    public init(sessionPreset: AVCaptureSession.Preset, @OutputServiceBuilder servicesBuilder: () -> [any OutputService]) {
        self.sessionPreset = sessionPreset
        self.outputServices = servicesBuilder()
    }
    
    /// Creates a capture profile.
    ///
    /// - Parameters:
    ///   - sessionPreset: The capture session preset to use.
    ///   - services: The output services associated with this profile.
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
    /// A predefined capture profile for photo capture, including Live Photo.
    public static func photo(options: PhotoCaptureOptions = .default) -> CameraCaptureProfile {
        CameraCaptureProfile(
            sessionPreset: .photo,
            services: [PhotoCaptureService(options: options)]
        )
    }
    
    /// A predefined capture profile for 1080p high-definition video recording.
    private static let hd1080p = CameraCaptureProfile(
        sessionPreset: .hd1920x1080,
        services: [MovieCaptureService()]
    )
    
    /// A predefined capture profile for 4K ultra-high-definition video recording.
    private static let hd4k = CameraCaptureProfile(
        sessionPreset: .hd4K3840x2160,
        services: [MovieCaptureService()]
    )
}
