//
//  PhotoReadinessCoordinatorDelegate.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import AVFoundation
import Foundation

final class PhotoReadinessCoordinatorDelegate: NSObject, AVCapturePhotoOutputReadinessCoordinatorDelegate {
    unowned var session: PhotoCaptureSession
    
    init(session: PhotoCaptureSession) {
        self.session = session
    }
    
    func readinessCoordinator(
        _ coordinator: AVCapturePhotoOutputReadinessCoordinator,
        captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness
    ) {
        session.shutterDisabled = captureReadiness != .ready
        session.isBusyProcessing = captureReadiness == .notReadyWaitingForProcessing
    }
}
