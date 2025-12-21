//
//  PhotoCaptureConfiguration.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import AVFoundation

@available(*, deprecated, renamed: "PhotoCaptureConfiguration")
public typealias PhotoConfiguration = PhotoCaptureConfiguration

public struct PhotoCaptureConfiguration: Hashable, Sendable {
    public var isLivePhoto: Bool
    public var qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization
    
    public init(
        isLivePhoto: Bool = false,
        qualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced
    ) {
        self.isLivePhoto = isLivePhoto
        self.qualityPrioritization = qualityPrioritization
    }
}
