import SwiftUI

/// Camera capture configuration for CameraModel to configure the session.
struct _CameraCaptureConfigurationKey: EnvironmentKey {
    static var defaultValue = CameraCaptureConfiguration()
}

extension EnvironmentValues {
    /// The environment value for modifiers to update the configurations.
    var _captureConfiguration: CameraCaptureConfiguration {
        get { self[_CameraCaptureConfigurationKey.self] }
        set { self[_CameraCaptureConfigurationKey.self] = newValue }
    }
}
