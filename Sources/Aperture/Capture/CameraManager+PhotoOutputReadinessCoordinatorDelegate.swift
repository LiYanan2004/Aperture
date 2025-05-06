import AVFoundation

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension CameraManager: AVCapturePhotoOutputReadinessCoordinatorDelegate {
    public func readinessCoordinator(_ coordinator: AVCapturePhotoOutputReadinessCoordinator, captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness) {
        self.shutterDisabled = captureReadiness != .ready
        self.isBusyProcessing = captureReadiness == .notReadyWaitingForProcessing
    }
}
