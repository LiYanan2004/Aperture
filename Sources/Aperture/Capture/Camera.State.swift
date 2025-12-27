//
//  Camera.State.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/27.
//

import Foundation
import AVFoundation

extension Camera {
    @Observable
    public final class State: SendableMetatype {
        unowned internal var camera: Camera!
        
        internal init(camera: Camera!) {
            self.camera = camera
        }
        
        /// A obvserable value indicates the current state of the session.
        public var captureSessionState: CaptureSessionState = .idle
        public enum CaptureSessionState {
            case idle
            case running
            case configuring
        }

        /// An observable angle to apply to the preview layer so that it’s level relative to gravity.
        ///
        /// You can use this value to rotate the UI of camera controls if you does not support certain orientation (for example: portrait mode only).
        internal(set) public var previewRotationAngle: CGFloat? = nil
        /// An observable angle to apply to photos or videos it captures with the device so that they’re level relative to gravity.
        internal(set) public var captureRotationAngle: CGFloat? = nil
        
        /// An observable boolean value indicates whether the preview layer is dimming.
        internal(set) public var previewDimming = false
        /// An observable boolean value indicates whether the system is busy processing captured photo.
        internal(set) public var isBusyProcessing = false
        /// An observable boolean value indicates whether the shutter is disabled for some reason.
        internal(set) public var shutterDisabled = false
        
        /// Requested photo capture options.
        ///
        /// > Tip:
        /// > You can update this value via ``setPhotoCaptureOptions(_:)``.
        /// >
        /// > Note that updating this vlaue after running the session will trigger a session re-configuration if the option updates.
        ///
        /// - SeeAlso: ``setPhotoCaptureOptions(_:)``
        internal(set) public var photoCaptureOptions: RequestedPhotoCaptureOptions = []
        /// An observable integer value indicates how many live photo capturing is in progress.
        internal(set) public var inProgressLivePhotoCount = 0
        
        /// An observable value indicates flash state of current capture device for the capturing.
        public var flash = CameraFlash(
            deviceEligible: false, // this will be updated during session setup
            userSelectedMode: .off,
            isFlashRecommendedByScene: false
        )
        
        /// An observable boolean value indicates whether the focus is locked by user (via long press).
        ///
        /// - SeeAlso: ``CameraViewFinder``
        internal(set) public var focusLocked = false
        
        #if os(iOS)
        /// A value that controls the cropping and enlargement of images based on current device factor.
        public var zoomFactor: CGFloat = 1.0 {
            didSet {
                guard oldValue != self.zoomFactor else { return }
                
                Task { @CameraActor [zoomFactor] in
                    camera.coordinator.isSettingZoomFactor = true
                    defer { camera.coordinator.isSettingZoomFactor = false }
                    
                    camera.coordinator.withCurrentCaptureDevice { device in
                        device.videoZoomFactor = zoomFactor
                    }
                }
            }
        }
        #else
        /// A value indicating the zoom factor of current capture device.
        ///
        /// On macOS, this value is always set to `1.0`.
        public let zoomFactor: CGFloat = 1.0
        #endif
        /// The zoom factor multiplier when displaying zoom information on a user interface.
        ///
        /// This maps the `1.0` value of `zoomFactor` to the display value on user interfaces.
        ///
        /// For example, the wide-angle camera may report a `zoomFactor` of `2.0` when your app uses iOS fusion camera.
        /// You can transform the value from device zoom factor to the displaying zoom factor and vice versa.
        ///
        /// - SeeAlso: ``displayZoomFactor``
        internal(set) public var displayZoomFactorMultiplier: CGFloat = 1.0
        /// A value to display zoom information in a user interface.
        ///
        /// This value represents the effective zoom relative to the base (wide-angle) camera, making it suitable for display in the user interface.
        public var displayZoomFactor: CGFloat {
            zoomFactor * displayZoomFactorMultiplier
        }
    }
}
