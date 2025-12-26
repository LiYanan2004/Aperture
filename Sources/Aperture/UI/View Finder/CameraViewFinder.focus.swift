//
//  CameraViewFinder.focus.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI
import AVFoundation

extension CameraViewFinder {
    struct _FocusGestureRespondingView: View {
        var camera: Camera
        
        @State private var focusGestureState = _CameraFocusGestureState()
        @GestureState private var isTouching = false
        
        var body: some View {
            Rectangle()
                .fill(.clear)
                .contentShape(.rect)
                #if os(iOS)
                .overlay {
                    if let manualFocusIndicatorPosition = focusGestureState.manualFocusIndicatorPosition {
                        _FocusTargetBoundingBox(
                            camera: camera,
                            focusMode: focusGestureState.manualFocusMode
                        )
                        .frame(width: 75, height: 75)
                        .position(manualFocusIndicatorPosition)
                        .id("focus rectangle at (\(manualFocusIndicatorPosition.x), \(manualFocusIndicatorPosition.y))")
                    }
                }
                .overlay {
                    if focusGestureState.showsAutoFocusBoundingBox {
                        _FocusTargetBoundingBox(
                            camera: camera,
                            focusMode: .autoFocus
                        )
                        .frame(width: 125, height: 125)
                    }
                }
                .coordinateSpace(.named("PREVIEW"))
                .gesture(
                    _TapToFocusGesture(session: camera, state: focusGestureState),
                    /* name: "camera-tap-to-focus", */
                    isEnabled: true
                )
                .gesture(
                    _TapHoldToLockFocusGesture(
                        session: camera,
                        state: focusGestureState,
                        isTouching: $isTouching
                    ),
                    /* name: "camera-tap-hold-to-lock-focus", */
                    isEnabled: true
                )
                .onChange(of: isTouching) {
                    guard isTouching == false else { return }
                    guard focusGestureState.manualFocusMode == .manualFocusLocking else { return }
                    
                    focusGestureState.manualFocusMode = .manualFocusLocked
                }
                .onChange(of: camera.captureSessionState == .running) {
                    focusGestureState.manualFocusIndicatorPosition = nil
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .AVCaptureDeviceSubjectAreaDidChange)
                ) { _ in
                    let coordinator = camera.coordinator
                    Task { @CameraActor in
                        coordinator.withCurrentCaptureDevice { device in
                            device.focusMode = .continuousAutoFocus
                            device.exposureMode = .continuousAutoExposure
                            device.setExposureTargetBias(.zero)
                            device.isSubjectAreaChangeMonitoringEnabled = false
                        }
                    }
                    focusGestureState.manualFocusIndicatorPosition = nil
                    focusGestureState.showsAutoFocusBoundingBox = true
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        withAnimation {
                            focusGestureState.showsAutoFocusBoundingBox = false
                        }
                    }
                }
                #endif
        }
    }
}

// MARK: - Gestures

extension CameraViewFinder {
    @Observable
    @MainActor
    final class _CameraFocusGestureState {
        #if os(iOS)
        
        var showsAutoFocusBoundingBox = false
        var manualFocusIndicatorPosition: CGPoint?
        var manualFocusMode = _FocusTargetBoundingBox.FocusMode.manualFocus
        
        func focus(at point: CGPoint, camera: Camera) {
            #if !targetEnvironment(simulator)
            let pointOfInterest = camera.coordinator.cameraPreview
                .preview
                .videoPreviewLayer
                .captureDevicePointConverted(fromLayerPoint: point)
            Task { @CameraActor in
                camera.setManualFocus(
                    pointOfInterst: pointOfInterest,
                    focusMode: .autoFocus,
                    exposureMode: .autoExpose
                )
            }
            #endif
        }
        
        func lockFocus(at point: CGPoint, camera: Camera) {
            #if !targetEnvironment(simulator)
            let pointOfInterest = camera.coordinator.cameraPreview
                .preview
                .videoPreviewLayer
                .captureDevicePointConverted(fromLayerPoint: point)
            Task { @CameraActor in
                camera.setManualFocus(
                    pointOfInterst: pointOfInterest,
                    focusMode: .locked,
                    exposureMode: .locked
                )
            }
            #endif
        }
        
        #endif
    }
    
    struct _TapHoldToLockFocusGesture: Gesture {
        var session: Camera
        var state: _CameraFocusGestureState
        
        var isTouching: GestureState<Bool>
        
        var body: some Gesture {
            DragGesture(minimumDistance: 0)
                #if os(iOS)
                .updating(isTouching) { value, isTouching, _ in
                    if isTouching == false {
                        isTouching = true
                        Task { [point = value.location] in
                            try await Task.sleep(for: .seconds(0.6))
                            
                            guard self.isTouching.wrappedValue else { return }
                            state.manualFocusMode = .manualFocusLocking
                            state.manualFocusIndicatorPosition = point
                            state.focus(at: point, camera: session)
                            
                            try await Task.sleep(for: .seconds(0.4))
                            guard self.isTouching.wrappedValue else {
                                state.manualFocusMode = .manualFocus
                                session.focusLocked = false
                                return
                            }
                            state.lockFocus(at: point, camera: session)
                            session.focusLocked = true
                        }
                    }
                }
                #endif
        }
    }
    
    @available(macOS, unavailable)
    struct _TapToFocusGesture: Gesture {
        var session: Camera
        var state: _CameraFocusGestureState
        
        var body: some Gesture {
            SpatialTapGesture()
                #if os(iOS)
                .onEnded {
                    session.focusLocked = false
                    state.manualFocusMode = .manualFocus
                    state.manualFocusIndicatorPosition = $0.location
                    state.focus(at: $0.location, camera: session)
                }
                #endif
        }
    }
}

