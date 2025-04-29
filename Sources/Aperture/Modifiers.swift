import SwiftUI
import AVFoundation

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Sets the device types for the camera session to find the appropriate capture device.
    ///
    /// On iOS, it uses a virtual device which consists of all physical lenses.
    ///
    /// On macOS, it uses wide-angle camera and continuity cameras.
    ///
    /// If you want to use a specific lens, you can use this modifier to configure the right lens.
    ///
    /// - note: Be sure to contain `.builtInWideAngleCamera` as a fallback camera.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func captureDeviceTypes(_ deviceTypes: AVCaptureDevice.DeviceType...) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if !os(watchOS) && !os(visionOS)
            configuration.captureDeviceTypes = deviceTypes
            #endif
        }
    }
    
    /// Set quality prioritization for output photos.
    ///
    /// Default value is `.balanced`.
    ///
    /// The better quality prioritization means it takes more time to process the photo.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func captureQualityPrioritization(_ prioritization: AVCapturePhotoOutput.QualityPrioritization) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if !os(watchOS) && !os(visionOS)
            configuration.preferedQualityPrioritization = prioritization
            #endif
        }
    }
    
    /// Enable auto deferred photo delivery if the device supports.
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(iOS 17.0, *)
    public func autoDeferredPhotoDeliveryEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferAutoDeferredPhotoDelivery = enabled
        }
    }
    
    /// Enable zero shutter lag if the device supports.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func zeroShutterLagEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferZeroShutterLag = enabled
        }
    }
    
    /// Enable responsive capture if the device supports.
    ///
    /// Zero shutter lag will be automatically enabled if you enable responsive capture.
    ///
    /// - parameter fastCapturePrioritized: A Boolean value that indicates whether the output enables fast capture prioritization.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func responsiveCaptureEnabled(_ enabled: Bool = true, fastCapturePrioritized: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferResponsiveCapture = enabled
            if enabled {
                configuration.preferZeroShutterLag = true
                configuration.preferFastCapturePrioritization = fastCapturePrioritized
            }
        }
    }

    /// Enable auto lens switching behavior when capture device consists of multiple lens.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    func autoSwitchingLensEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoSwitchingLens = enabled
        }
    }
    
    /// Enable multitasking camera access if the device supports.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func captureWhenMultiTaskingEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.captureWhenMultiTasking = enabled
        }
    }
    
    /// Sets prefered camera stabilization mode.
    @available(macOS, unavailable)
    @available(iOS 17.0, tvOS 17.0, *)
    public func cameraStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if os(iOS) || os(tvOS)
            configuration.stabilizationMode = mode
            #endif
        }
    }
    
    /// Prefer capture content in constant color if the device is capable.
    ///
    /// - note: If flash mode is off, constant color will be disabled even if the device is capable.
    @available(iOS 18.0, tvOS 18.0, macOS 15.0, *)
    public func cameraConstantColorEnabled(_ enabled: Bool = true, fallbackDeliveryEnabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferConstantColor = enabled
            configuration.enableConstantColorFallbackDelivery = enabled
        }
    }
}
