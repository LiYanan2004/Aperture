//
//  CameraDevice.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation
import Foundation

/// A type describes a recognizable camera device.
@_typeEraser(AnyCameraDevice)
@dynamicMemberLookup
public protocol CameraDevice: Identifiable, Equatable {
    var captureDevice: AVCaptureDevice? { get }
}

/// A type describes the built-in camera.
public protocol BuiltInCamera: CameraDevice {
    /// The position of the camera.
    var position: CameraPosition { get }
}

extension CameraDevice {
    public subscript<T>(dynamicMember keyPath: KeyPath<AVCaptureDevice?, T>) -> T {
        captureDevice[keyPath: keyPath]
    }
    
    public var id: String? { captureDevice?.uniqueID }
    
    /// A Boolean value indicates whether the device is a fusion camera composed of multiple lenses.
    public var isFusionCamera: Bool {
        #if os(iOS)
        (captureDevice?.isVirtualDevice == true) && (captureDevice?.virtualDeviceSwitchOverVideoZoomFactors.isEmpty == false)
        #else
        false
        #endif
    }
}

// MARK: - AnyCameraDevice

/// A type-erases camera device.
public struct AnyCameraDevice {
    /// The base camera device object.
    public let base: any CameraDevice
    
    public init<C: CameraDevice>(_ camera: C) {
        if let base = camera as? AnyCameraDevice {
            self = base
        } else {
            self.base = camera
        }
    }
    
    @inlinable
    public init<T: CameraDevice>(erasing camera: T) {
        self.init(camera)
    }
}

extension AnyCameraDevice: CameraDevice {
    public var captureDevice: AVCaptureDevice? { base.captureDevice }
    
    public static func == (lhs: AnyCameraDevice, rhs: AnyCameraDevice) -> Bool {
        lhs.eraseToAnyEquatable() == rhs.eraseToAnyEquatable()
    }
}
