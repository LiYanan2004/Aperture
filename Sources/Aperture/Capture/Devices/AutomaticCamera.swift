//
//  AutomaticCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation
import Foundation
import Observation

/// A camera device that resolves to a preferred camera and falls back to the platform default built-in camera.
public struct AutomaticCamera: SemanticCamera {
    /// A preference that determines which preferred camera to use.
    public enum Preference: Sendable {
        case systemPreferred
        case userPreferred
    }
    
    public var captureDevice: AVCaptureDevice? {
        switch preference {
            case .systemPreferred:
                AVCaptureDevice.systemPreferredCamera ?? BuiltInCamera().captureDevice
            case .userPreferred:
                AVCaptureDevice.userPreferredCamera ?? BuiltInCamera().captureDevice
        }
    }
    public let preference: Preference
    
    /// Creates an automatic camera using the specified preference.
    public init(preference: Preference) {
        self.preference = preference
    }
}

extension SemanticCamera where Self == AutomaticCamera {
    /// An automatic camera that resolves to the system-preferred device when available.
    ///
    /// This might result in a single camera instead of a fusion camera; if you're working on an iOS app, use ``builtInCamera`` instead.
    public static var systemPreferred: AutomaticCamera {
        .init(preference: .systemPreferred)
    }
    
    /// An automatic camera that resolves to the user-preferred device when available.
    public static var userPreferred: AutomaticCamera {
        .init(preference: .userPreferred)
    }
}
