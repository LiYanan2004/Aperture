//
//  Camera.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import AVFoundation
import Foundation

@_typeEraser(AnyCamera)
public protocol Camera: Identifiable, Equatable {
    var device: AVCaptureDevice? { get }
    var position: CameraPosition { get }
}

extension Camera {
    public var id: String? { device?.uniqueID }
    
    public var isFusionCamera: Bool {
        #if os(iOS)
        (device?.isVirtualDevice == true) && (device?.virtualDeviceSwitchOverVideoZoomFactors.isEmpty == false)
        #else
        false
        #endif
    }
}

// MARK: - AnyCamera

public struct AnyCamera: Camera {
    public var device: AVCaptureDevice?
    public var position: CameraPosition
    
    public init<C: Camera>(_ camera: C) {
        self.device = camera.device
        self.position = camera.position
    }
    
    @inlinable
    public init<T: Camera>(erasing camera: T) {
        self.init(camera)
    }
}
