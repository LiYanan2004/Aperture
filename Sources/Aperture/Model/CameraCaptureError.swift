import Foundation

/// The error that might occurred when using CameraView.
public enum CameraError: Sendable, Error {
    /// User has denied camera permission.
    case permissionDenied
    /// An errror occurred when trying to capture a photo.
    case captureError(_ message: Error)
}
