//
//  Camera.PhotoCapture.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/27.
//

import Foundation
import AVFoundation

extension Camera {
    /// Takes a photo of current scene.
    nonisolated public func takePhoto(
        configuration: PhotoCaptureConfiguration,
        dataRepresentationCustomizer: (any AVCapturePhotoFileDataRepresentationCustomizer)? = nil
    ) async throws -> CapturedPhoto {
        let context = await coordinator.outputContext(for: PhotoCaptureService.self)
        guard let context else { throw CaptureError.noContext }
        
        let photoOutput = await coordinator.captureOutput(of: PhotoCaptureService.self)
        let service = profile.photoCaptureService
        guard let photoOutput, let service else { throw CaptureError.photoOutputServiceNotAvailable }
        
        let photoSettings = try await service.createPhotoSettings(
            output: photoOutput,
            configuration: configuration,
            context: context
        )
        let capturedPhoto = try await withPhotoOutputReadinessCoordinatorTracking(
            output: photoOutput,
            photoSettings: photoSettings
        ) {
            try await withCheckedThrowingContinuation { continuation in
                let delegate = PhotoCaptureDelegate(
                    camera: self,
                    dataRepresentationCustomizer: dataRepresentationCustomizer,
                    continuation: continuation
                )
                inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = delegate

                photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
            }
        }
        
        inFlightPhotoCaptureDelegates[photoSettings.uniqueID] = nil
        
        return capturedPhoto
    }
    
    private func withPhotoOutputReadinessCoordinatorTracking<T>(
        output: AVCapturePhotoOutput,
        photoSettings: AVCapturePhotoSettings,
        perform action: () async throws -> T
    ) async rethrows -> T {
        var readinessCoordinator: AVCapturePhotoOutputReadinessCoordinator?
        #if os(iOS)
        readinessCoordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: output)
        
        let delegate = PhotoReadinessCoordinatorDelegate(camera: self)
        defer { _ = delegate }
        readinessCoordinator?.delegate = delegate
        #endif
        
        readinessCoordinator?.startTrackingCaptureRequest(using: photoSettings)
        defer { readinessCoordinator?.stopTrackingCaptureRequest(using: photoSettings.uniqueID) }
        return try await action()
    }
}

// MARK: - Delegate

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

