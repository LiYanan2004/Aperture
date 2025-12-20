//
//  RequestedCaptureOptions.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import Foundation

public struct RequestedCaptureOptions: OptionSet, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// Capture photos with zero shutter lag if supported.
    static public let zeroShutterLag = RequestedCaptureOptions(rawValue: 1 << 0)
    /// Enable responsive capture to reduce capture latency.
    static public let responsiveCapture = RequestedCaptureOptions(rawValue: 1 << 1)
    /// Prioritize faster capture performance over quality.
    static public let fastCapturePrioritization = RequestedCaptureOptions(rawValue: 1 << 2)
    /// Allow deferred photo delivery to improve performance.
    static public let autoDeferredPhotoDelivery = RequestedCaptureOptions(rawValue: 1 << 3)
    /// Capture photos with consistent color rendering.
    static public let constantColor = RequestedCaptureOptions(rawValue: 1 << 4)
}
