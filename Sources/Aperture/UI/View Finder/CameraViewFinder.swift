//
//  CameraViewFinder.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI
import AVFoundation

public struct CameraViewFinder: View {
    public var camera: Camera
    
    public enum VideoGravity: Sendable {
        case fit
        case fill
        
        var avLayerVideoGravity: AVLayerVideoGravity {
            switch self {
                case .fit:
                    AVLayerVideoGravity.resizeAspect
                case .fill:
                    AVLayerVideoGravity.resizeAspectFill
            }
        }
    }
    public var videoGravity: VideoGravity
    
    public struct Gestures: OptionSet, Sendable {
        public var rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        public static let zoom = Gestures(rawValue: 1 << 0)
        public static let focus = Gestures(rawValue: 1 << 1)
    }
    public var gestures: Gestures
    
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
            .onChange(of: camera.device.id, initial: true) {
                guard let builtInCamera = camera.device as? BuiltInCamera else { return }
                position = builtInCamera.position
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

    private var dimmingLayer: some View {
        Color.black
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
