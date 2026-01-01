//
//  SemanticCamera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation
import Foundation

/// A type that describes a recognizable camera device.
@_typeEraser(AnySemanticCamera)
@dynamicMemberLookup
public protocol SemanticCamera: Hashable {
    /// The underlying `AVCaptureDevice` used for capture, or `nil` when the device isn't available.
    var captureDevice: AVCaptureDevice? { get }
    /// The physical position of the camera, or `nil` if the device is not a built-in device.
    var position: CameraPosition? { get }
}

extension SemanticCamera {
    /// Returns the value at the key path on the underlying capture device.
    public subscript<T>(dynamicMember keyPath: KeyPath<AVCaptureDevice?, T>) -> T {
        captureDevice[keyPath: keyPath]
    }
    
    public var position: CameraPosition? {
        nil
    }
    
    /// A localized display name for the underlying capture device, or `nil` when unavailable.
    public var localizedName: String? {
        captureDevice?.localizedName
    }
    
    /// An ID unique to the model of device, or `nil` when unavailable.
    public var uniqueID: String? {
        captureDevice?.uniqueID
    }
    
    /// A Boolean value indicates whether the device is a fusion camera composed of multiple lenses.
    public var isFusionCamera: Bool {
        #if os(iOS)
        (captureDevice?.isVirtualDevice == true) && (captureDevice?.virtualDeviceSwitchOverVideoZoomFactors.isEmpty == false)
        #else
        false
        #endif
    }
}

// MARK: - AnySemanticCamera

/// A type-erased camera device.
public struct AnySemanticCamera {
    /// The base camera device object.
    public let base: any SemanticCamera
    
    public init<C: SemanticCamera>(_ camera: C) {
        if let base = camera as? AnySemanticCamera {
            self = base
        } else {
            self.base = camera
        }
    }
    
    @inlinable
    public init<T: SemanticCamera>(erasing camera: T) {
        self.init(camera)
    }
}

extension AnySemanticCamera: SemanticCamera {
    public var captureDevice: AVCaptureDevice? { base.captureDevice }
    public var position: CameraPosition? { base.position }
    
    public func hash(into hasher: inout Hasher) {
        base.hash(into: &hasher)
    }
    
    public static func == (lhs: AnySemanticCamera, rhs: AnySemanticCamera) -> Bool {
        lhs.base.eraseToAnyEquatable() == rhs.base.eraseToAnyEquatable()
    }
}
