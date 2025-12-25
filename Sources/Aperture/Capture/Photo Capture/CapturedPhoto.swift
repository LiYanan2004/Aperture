//
//  CapturedPhoto.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/29.
//

import AVFoundation
import SwiftUI

@available(visionOS, unavailable)
@available(watchOS, unavailable)
public struct CapturedPhoto: Sendable {
    public var data: Data
    public let isProxy: Bool
    public let livePhotoMovieURL: URL?
    public var isLivePhoto: Bool { livePhotoMovieURL != nil }
    
    init(data: Data, isProxy: Bool, livePhotoMovieURL: URL?) {
        self.data = data
        self.isProxy = isProxy
        self.livePhotoMovieURL = livePhotoMovieURL
    }
}
