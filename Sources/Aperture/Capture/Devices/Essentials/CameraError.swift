//
//  CameraError.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import Foundation

public enum CameraError: LocalizedError {
    case invalidCaptureDevice
    case permissionDenied
    case sessionAlreadStarted
    
    public var errorDescription: String? {
        switch self {
            case .invalidCaptureDevice:
                "Invalid capture device is specified."
            case .permissionDenied:
                "User denied the camera access."
            case .sessionAlreadStarted:
                "AVCaptureSession is currently running, no need to run it again."
        }
    }
}
