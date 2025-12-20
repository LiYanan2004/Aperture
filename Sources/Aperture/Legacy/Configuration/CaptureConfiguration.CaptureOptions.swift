//
//  CaptureConfiguration.CaptureOptions.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import Foundation

extension CaptureConfiguration {
    public struct CaptureOptions: OptionSet, Sendable {
        public var rawValue: UInt
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        /// Capture photos with zero shutter lag if supported.
        static public let zeroShutterLag = CaptureOptions(rawValue: 1 << 0)
        /// Enable responsive capture to reduce capture latency.
        static public let responsiveCapture = CaptureOptions(rawValue: 1 << 1)
        /// Prioritize faster capture performance over quality.
        static public let fastCapturePrioritization = CaptureOptions(rawValue: 1 << 2)
        /// Allow deferred photo delivery to improve performance.
        static public let autoDeferredPhotoDelivery = CaptureOptions(rawValue: 1 << 3)
        /// Capture photos with consistent color rendering.
        static public let constantColor = CaptureOptions(rawValue: 1 << 4)
        /// Deliver fallback photo when constant color capture confidence is low.
        static public let constantColorFallbackDelivery = CaptureOptions(rawValue: 1 << 5)
    }
    
    public enum CaptureOptionFlag: Sendable {
        case enabledWhenAvailable
        case disabled
    }
    
    nonisolated public func zeroShutterLag(
        _ flag: CaptureOptionFlag
    ) -> CaptureConfiguration {
        var config = self
        config._toggleCapabilities(.zeroShutterLag, flag)
        return config
    }
    
    nonisolated public func responsiveCapture(
        _ flag: CaptureOptionFlag,
        fastCapturePrioritizationEnabled: Bool = true
    ) -> CaptureConfiguration {
        var config = self
        var options = CaptureOptions.responsiveCapture
        if flag == .enabledWhenAvailable {
            // Zero shutter lag must be enabled to support responsive capture.
            options.insert(.zeroShutterLag)
        }
        if fastCapturePrioritizationEnabled {
            options.insert(.fastCapturePrioritization)
        }
        config._toggleCapabilities(options, flag)
        return config
    }
    
    nonisolated public func autoDeferredPhotoDelivery(
        _ flag: CaptureOptionFlag
    ) -> CaptureConfiguration {
        var config = self
        config._toggleCapabilities(.autoDeferredPhotoDelivery, flag)
        return config
    }
    
    nonisolated public func constantColor(
        _ flag: CaptureOptionFlag,
        fallbackDelivery: Bool = true
    ) -> CaptureConfiguration {
        var config = self
        var options = CaptureOptions.constantColor
        if fallbackDelivery {
            options.insert(.constantColorFallbackDelivery)
        }
        config._toggleCapabilities(options, flag)
        return config
    }
    
    mutating private func _toggleCapabilities(
        _ capabilities: CaptureOptions,
        _ flag: CaptureOptionFlag
    ) {
        switch flag {
        case .enabledWhenAvailable:
            self.preferredCaptureOptions.formUnion(capabilities)
        case .disabled:
            self.preferredCaptureOptions.subtract(capabilities)
        }
    }
}
