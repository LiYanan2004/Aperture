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
    case unsatisfiablePhotoCaptureConfiguration(key: PartialKeyPath<PhotoCaptureConfiguration>)
    case sessionAlreadStarted
    case failedToAddOutput
    case failedToAddInput
    
    public var errorDescription: String? {
        switch self {
            case .invalidCaptureDevice:
                "Invalid capture device is specified."
            case .permissionDenied:
                "User denied the camera access."
            case .sessionAlreadStarted:
                "AVCaptureSession is currently running, no need to run it again."
            case .unsatisfiablePhotoCaptureConfiguration(let key):
                "No available option satisfies the photo capture configuration for key: \(key)."
            case .failedToAddInput:
                "Failed to add the capture input to the session."
            case .failedToAddOutput:
                "Failed to add the capture output to the session."
        }
    }
}
