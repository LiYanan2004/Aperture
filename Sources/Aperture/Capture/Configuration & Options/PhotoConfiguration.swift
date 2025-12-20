//
//  PhotoConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import AVFoundation

public struct PhotoConfiguration: Sendable, Hashable {
    public var qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced
    
    public init(qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced) {
        self.qualityPrioritization = qualityPrioritization
    }
}
