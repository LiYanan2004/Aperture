//
//  CameraError.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/14.
//

import Foundation

enum CameraError: LocalizedError {
    case invalidCaptureDevice
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
            case .invalidCaptureDevice:
                "Invalid capture device is specified."
            case .permissionDenied:
                "User denied the camera access."
        }
    }
}
