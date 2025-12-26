//
//  PhotoCaptureConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/22.
//

import AVFoundation

public struct PhotoCaptureConfiguration: Hashable, Sendable {
    public var capturesLivePhoto: Bool = false
    public var resolution: Resolution = .maximumSupported
    public var qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced
    
    public init(
        capturesLivePhoto: Bool = false,
        resolution: Resolution = .maximumSupported,
        qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced
    ) {
        self.capturesLivePhoto = capturesLivePhoto
        self.resolution = resolution
        self.qualityPrioritization = qualityPrioritization
    }
    
    public enum Resolution: Sendable, Hashable {
        case maximumSupported
        case `48mp`
        case `12mp`
        
        var _minimumPixelCount: Int32? {
            switch self {
                case .maximumSupported: nil
                case .`48mp`: 48_000_000
                case .`12mp`: 12_000_000
            }
        }
    }
}
