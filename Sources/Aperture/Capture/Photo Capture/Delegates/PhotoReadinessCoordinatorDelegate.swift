//
//  PhotoReadinessCoordinatorDelegate.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import AVFoundation
import Foundation

final class PhotoReadinessCoordinatorDelegate: NSObject, AVCapturePhotoOutputReadinessCoordinatorDelegate {
    unowned var camera: Camera
    
    init(camera: Camera) {
        self.camera = camera
    }
    
    func readinessCoordinator(
        _ coordinator: AVCapturePhotoOutputReadinessCoordinator,
        captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness
    ) {
        camera.shutterDisabled = captureReadiness != .ready
        camera.isBusyProcessing = captureReadiness == .notReadyWaitingForProcessing
    }
}
