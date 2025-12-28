//
//  CameraDevice.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation
import Foundation

@_typeEraser(AnyCameraDevice)
@dynamicMemberLookup
public protocol CameraDevice: Identifiable, Equatable {
    var captureDevice: AVCaptureDevice? { get }
}

public protocol BuiltInCamera: CameraDevice {
    var position: CameraPosition { get }
}

extension CameraDevice {
    public subscript<T>(dynamicMember keyPath: KeyPath<AVCaptureDevice?, T>) -> T {
        captureDevice[keyPath: keyPath]
    }
    
    public var id: String? { captureDevice?.uniqueID }
    
    public var isFusionCamera: Bool {
        #if os(iOS)
        (captureDevice?.isVirtualDevice == true) && (captureDevice?.virtualDeviceSwitchOverVideoZoomFactors.isEmpty == false)
        #else
        false
        #endif
    }
}

// MARK: - AnyCameraDevice

public struct AnyCameraDevice {
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
