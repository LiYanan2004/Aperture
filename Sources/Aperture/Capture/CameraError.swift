//
//  CameraError.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import Foundation

/// A value describes the error occurred during capture.
@_documentation(visibility: internal)
public enum CaptureError: LocalizedError {
    case photoOutputServiceNotAvailable
    case movieOutputServiceNotAvailable
    case noContext
    
    public var errorDescription: String? {
        switch self {
            case .photoOutputServiceNotAvailable:
                "Photo output service is not available."
            case .movieOutputServiceNotAvailable:
                "Movie output service is not available."
            case .noContext:
                "Failed to construct context for this service."
        }
    }
}

/// A value describes a general camera error.
@_documentation(visibility: internal)
public enum CameraError: LocalizedError {
    case invalidCaptureDevice
    case permissionDenied
    case unsatisfiablePhotoCaptureConfiguration(key: PartialKeyPath<PhotoCaptureConfiguration>)
    case sessionAlreadStarted
    case failedToAddOutput
    case failedToAddInput
    case failedToUpdateOutputService
    
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
            case .failedToUpdateOutputService:
                "Failed to update output service"
        }
    }
}
