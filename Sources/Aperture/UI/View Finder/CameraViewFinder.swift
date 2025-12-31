//
//  CameraViewFinder.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI
import AVFoundation

/// Camera view finder that displays the field of view of current capture device.
public struct CameraViewFinder: View {
    /// The camera view model.
    public var camera: Camera
    
    /// A value describes how preview layer displays the content within the view bounds.
    public enum VideoGravity: Sendable {
        /// The content fits within the view bounds.
        case fit
        /// The content fills the view bounds.
        case fill
        
        /// The coresponding `AVLayerVideoGravity` value.
        internal var avLayerVideoGravity: AVLayerVideoGravity {
            switch self {
                case .fit:
                    AVLayerVideoGravity.resizeAspect
                case .fill:
                    AVLayerVideoGravity.resizeAspectFill
            }
        }
    }
    /// A value that specifies how preview layer displays the content within the view bounds.
    public var videoGravity: VideoGravity
    
    /// A value describes camera gestures enabled for this view.
    public struct Gestures: OptionSet, Sendable {
        public var rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        /// Pintch-to-zoom gesture.
        public static let zoom = Gestures(rawValue: 1 << 0)
        /// Tap-to-focus gesture, as well as press-and-hold to lock focus gesture.
        public static let focus = Gestures(rawValue: 1 << 1)
    }
    /// A value indicating camera gestures enabled for this view.
    public var gestures: Gestures
    
    /// Creates a camera view finder that displays the field of view of current capture device.
    public init(
        camera: Camera,
        videoGravity: VideoGravity = .fit,
        gestures: Gestures = [.zoom, .focus]
    ) {
        self.camera = camera
        self.videoGravity = videoGravity
        self.gestures = gestures
    }
    
    @State private var cameraError: CameraError?
    @State private var position: CameraPosition?
    
    public var body: some View {
        Rectangle()
            .fill(.black)
            .overlay {
                camera.coordinator.cameraPreview
                    .opacity(camera.previewDimming ? 0 : 1)
            }
            .blur(radius: camera.captureSessionState == .running ? 0 : 15, opaque: true)
            .modifier(_FlipViewModifier(trigger: position ?? .platformDefault))
            .onChange(of: camera.device.uniqueID, initial: true) {
                position = camera.device.position
            }
            .onChange(of: videoGravity, initial: true) {
                camera.coordinator.cameraPreview.setVideoGravity(videoGravity.avLayerVideoGravity)
            }
            .overlay {
                if gestures.contains(.focus) {
                    _FocusGestureRespondingView(camera: camera)
                }
            }
            .simultaneousGesture(
                _ZoomGesture(camera: camera),
                /* name: "camera-zoom", */
                isEnabled: gestures.contains(.zoom)
            )
            .clipped()
            .disabled(camera.captureSessionState != .running)
    }
    
    @ViewBuilder
    private var errorOverlay: some View {
        if let cameraError {
            ContentUnavailableView(
                "Camera Unavailable",
                systemImage: "xmark.octagon",
                description: Text(cameraError.localizedDescription)
            )
        }
    }
}
