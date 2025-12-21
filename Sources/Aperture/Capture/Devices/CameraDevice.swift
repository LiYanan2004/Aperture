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
    var device: AVCaptureDevice? { get }
    var position: CameraPosition { get }
}

extension CameraDevice {
    public subscript<T>(dynamicMember keyPath: KeyPath<AVCaptureDevice?, T>) -> T {
        device[keyPath: keyPath]
    }
    
    public var id: String? { device?.uniqueID }
    
    public var isFusionCamera: Bool {
        #if os(iOS)
        (device?.isVirtualDevice == true) && (device?.virtualDeviceSwitchOverVideoZoomFactors.isEmpty == false)
        #else
        false
        #endif
    }
}

// MARK: - AnyCameraDevice

public struct AnyCameraDevice: CameraDevice {
    public var device: AVCaptureDevice?
    public var position: CameraPosition
    
    public init<C: CameraDevice>(_ camera: C) {
        self.device = camera.device
        self.position = camera.position
    }
    
    @inlinable
    public init<T: CameraDevice>(erasing camera: T) {
        self.init(camera)
    }
}
