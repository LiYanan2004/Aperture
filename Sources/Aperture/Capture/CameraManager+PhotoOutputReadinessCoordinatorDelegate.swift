import AVFoundation

extension CameraManager: AVCapturePhotoOutputReadinessCoordinatorDelegate {
    public func readinessCoordinator(_ coordinator: AVCapturePhotoOutputReadinessCoordinator, captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness) {
        self.shutterDisabled = captureReadiness != .ready
        self.isBusyProcessing = captureReadiness == .notReadyWaitingForProcessing
    }
}
