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
        var session: CameraSession
        
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
                            session: session,
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
                            session: session,
                            focusMode: .autoFocus
                        )
                        .frame(width: 125, height: 125)
                    }
                }
                .coordinateSpace(.named("PREVIEW"))
                .gesture(
                    _TapToFocusGesture(session: session, state: focusGestureState),
                    /* name: "camera-tap-to-focus", */
                    isEnabled: true
                )
                .gesture(
                    _TapHoldToLockFocusGesture(
                        session: session,
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
                .onChange(of: session.captureSession.isRunning) {
                    focusGestureState.manualFocusIndicatorPosition = nil
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .AVCaptureDeviceSubjectAreaDidChange)
                ) { _ in
                    session.withCurrentCaptureDevice { device in
                        device.focusMode = .continuousAutoFocus
                        device.exposureMode = .continuousAutoExposure
                        device.setExposureTargetBias(.zero)
                        device.isSubjectAreaChangeMonitoringEnabled = false
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
    final class _CameraFocusGestureState {
        #if os(iOS)
        typealias Session = CameraSession
        
        var showsAutoFocusBoundingBox = false
        var manualFocusIndicatorPosition: CGPoint?
        var manualFocusMode = _FocusTargetBoundingBox.FocusMode.manualFocus
        
        func setAutoFocus(at point: CGPoint, session: Session) {
            let pointOfInterest = session.cameraPreview
                .preview
                .videoPreviewLayer
                .captureDevicePointConverted(fromLayerPoint: point)
            #if !targetEnvironment(simulator)
            session.setManualFocus(
                pointOfInterst: pointOfInterest,
                focusMode: .autoFocus,
                exposureMode: .autoExpose
            )
            #endif
        }
        
        func setLockedFocus(at point: CGPoint, session: Session) {
            let pointOfInterest = session.cameraPreview
                .preview
                .videoPreviewLayer
                .captureDevicePointConverted(fromLayerPoint: point)
            #if !targetEnvironment(simulator)
            session.setManualFocus(
                pointOfInterst: pointOfInterest,
                focusMode: .locked,
                exposureMode: .locked
            )
            #endif
        }
        #endif
    }
    
    struct _TapHoldToLockFocusGesture: Gesture {
        var session: CameraSession
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
                            state.setAutoFocus(at: point, session: session)
                            
                            try await Task.sleep(for: .seconds(0.4))
                            guard self.isTouching.wrappedValue else {
                                state.manualFocusMode = .manualFocus
                                session.focusLocked = false
                                return
                            }
                            state.setLockedFocus(at: point, session: session)
                            session.focusLocked = true
                        }
                    }
                }
                #endif
        }
    }
    
    @available(macOS, unavailable)
    struct _TapToFocusGesture: Gesture {
        var session: CameraSession
        var state: _CameraFocusGestureState
        
        var body: some Gesture {
            SpatialTapGesture()
                #if os(iOS)
                .onEnded {
                    session.focusLocked = false
                    state.manualFocusMode = .manualFocus
                    state.manualFocusIndicatorPosition = $0.location
                    state.setAutoFocus(at: $0.location, session: session)
                }
                #endif
        }
    }
}

