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
    nonisolated public func takePhoto(configuration: PhotoCaptureConfiguration) async throws -> CapturedPhoto {
        let context = await coordinator.outputContext(for: PhotoCaptureService.self)
        guard let context else { throw CaptureError.noContext }
        
        let photoOutput = await coordinator.activeOutputs.first(byUnwrapping: { $0 as? AVCapturePhotoOutput })
        let service = profile.photoCaptureService
        guard let photoOutput, let service else { throw CaptureError.photoOutputServiceNotAvailable }
        
        let photoSettings = try await service.photoSettings(
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
