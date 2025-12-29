//
//  CameraFlash.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import AVFoundation

/// A type that determines whether flash will be used based on user preference and scene conditions.
public struct CameraFlash: Hashable, Sendable {
    /// A boolean value indicating whether flash is available on this device.
    internal(set) public var deviceEligible: Bool
    /// The user-preferred / app-preferred flash mode.
    public var userSelectedMode: AVCaptureDevice.FlashMode
    /// Indicates whether current scene analysis suggests that flash should be used.
    internal(set) public var isFlashRecommendedByScene: Bool
    
    /// A Boolean value indicating whether flash will be used for the current capture.
    ///
    /// You can tint controls based on this value to indicate user that flash will be used for this capture.
    public var isEnabled: Bool {
        guard deviceEligible else { return false }
        
        return switch userSelectedMode {
            case .off:
                false
            case .on:
                true
            case .auto:
                isFlashRecommendedByScene
            @unknown default:
                fatalError("Unknown flash mode")
        }
    }
}
