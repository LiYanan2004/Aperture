//
//  CaptureConfiguration.PhotoSettings.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import AVFoundation

extension CaptureConfiguration {
    public struct PhotoSettings: Sendable, Hashable {
        /// Determine how photo pipeline adjust the photo (reduce noise, sharper details and more.)
        public var qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced
    }
    
    nonisolated public func photoQualityPrioritization(
        _ prioritization: AVCapturePhotoOutput.QualityPrioritization
    ) -> CaptureConfiguration {
        var config = self
        config.photoSettings.qualityPrioritization = prioritization
        return config
    }
}
