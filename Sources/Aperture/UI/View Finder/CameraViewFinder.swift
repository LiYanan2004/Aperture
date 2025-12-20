//
//  CameraViewFinder.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI
import AVFoundation

public struct CameraViewFinder: View {
    public var session: CameraSession
    
    public struct Gestures: OptionSet, Sendable {
        public var rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        public static let zoom = Gestures(rawValue: 1 << 0)
        public static let focus = Gestures(rawValue: 1 << 1)
    }
    public var gestures: Gestures
    
    public init(session: CameraSession, gestures: Gestures = [.zoom, .focus]) {
        self.session = session
        self.gestures = gestures
    }
    
    @State private var cameraError: CameraError?
    
    public var body: some View {
        Rectangle()
            .fill(.clear)
            .overlay { session.cameraPreview }
            .overlay { dimmingLayer }
            .overlay { errorOverlay }
            .task { await _runSession() }
            .onDisappear {
                session.captureSession.stopRunning()
            }
            .overlay {
                if gestures.contains(.focus) {
                    _FocusGestureRespondingView(session: session)
                }
            }
            .simultaneousGesture(
                _ZoomGesture(session: session),
                /* name: "camera-zoom", */
                isEnabled: gestures.contains(.zoom)
            )
            .clipped()
    }
    
    @MainActor
    private func _runSession() async {
        do {
            try await self.session.setupSession()
            session._setupRotationCoordinator()
            let captureSession = session.captureSession
            Task { @concurrent in
                if !captureSession.isRunning {
                    captureSession.startRunning()
                }
            }
        } catch let error as CameraError {
            self.cameraError = error
        } catch {
            session.logger.error("\(error)")
        }
    }
    
    private var dimmingLayer: some View {
        Color.black.opacity(session.previewDimming ? 1 : 0)
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
