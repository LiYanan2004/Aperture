//
//  CameraPosition.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/9.
//

import AVFoundation

/// Constants that indicate the physical position of a capture device.
public enum CameraPosition: Int, Sendable, Hashable, CustomStringConvertible {
    @available(macOS, unavailable)
    case back = 1
    case front = 2
    
    public static var platformDefault: Self {
        #if os(macOS) || targetEnvironment(macCatalyst)
        .front
        #else
        .back
        #endif
    }
    
    public var description: String {
        switch self {
            case .back: "Back Camera"
            case .front: "Front Camera"
        }
    }
    
    @available(macOS, unavailable)
    public var flipped: CameraPosition {
        var copy = self
        copy.toggle()
        return copy
    }
    
    @available(macOS, unavailable)
    public mutating func toggle() {
        self = self == .front ? .back : .front
    }
}

extension AVCaptureDevice.Position {
    public init(position: CameraPosition) {
        switch position {
            case .back: self = .back
            case .front: self = .front
        }
    }
}
