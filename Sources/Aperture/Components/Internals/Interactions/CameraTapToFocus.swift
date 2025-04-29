import SwiftUI
import AVFoundation

extension View {
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    func allowsTapToFocus(_ flag: Bool = true) -> some View {
        #if os(iOS)
        modifier(_CameraTapToFocusModifier())
        #else
        self
        #endif
    }
}

#if os(iOS) || os(tvOS)
@available(macOS, unavailable)
struct _CameraTapToFocusModifier: ViewModifier {
    @State private var showAutoFocusIndicator = false
    @State private var manualFocusIndicatorPosition: CGPoint?
    @Environment(Camera.self) private var camera
    
    @GestureState private var isTouching = false
    @State private var manualFocusMode = FocusIndicator.FocusMode.manualFocus
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if let manualFocusIndicatorPosition {
                    GeometryReader { previewProxy in
                        FocusIndicator(focusMode: manualFocusMode)
                            .frame(width: 75, height: 75)
                            .position(manualFocusIndicatorPosition)
                            .id("focus rectangle at (\(manualFocusIndicatorPosition.x), \(manualFocusIndicatorPosition.y))")
                    }
                }
            }
            .overlay {
                if showAutoFocusIndicator {
                    FocusIndicator(focusMode: .autoFocus)
                        .frame(width: 125, height: 125)
                }
            }
            .coordinateSpace(.named("PREVIEW"))
            .gesture(autoFocusGesture)
            .gesture(lockFocusGesture)
            .onChange(of: isTouching) {
                if isTouching == false && manualFocusMode == .manualFocusLocking {
                    manualFocusMode = .manualFocusLocked
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVCaptureDeviceSubjectAreaDidChange)) { _ in
                camera.configureCaptureDevice { device in
                    device.focusMode = .continuousAutoFocus
                    device.exposureMode = .continuousAutoExposure
                    device.setExposureTargetBias(.zero)
                    device.isSubjectAreaChangeMonitoringEnabled = false
                }
                manualFocusIndicatorPosition = nil
                showAutoFocusIndicator = true
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    withAnimation {
                        showAutoFocusIndicator = false
                    }
                }
            }
            .onChange(of: camera.sessionState) {
                if camera.sessionState == .committing {
                    manualFocusIndicatorPosition = nil
                }
            }
    }
    
    var autoFocusGesture: some Gesture {
        SpatialTapGesture()
            .onEnded {
                camera.focusLocked = false
                manualFocusMode = .manualFocus
                manualFocusIndicatorPosition = $0.location
                setAutoFocus(at: $0.location)
            }
    }
    
    private var lockFocusGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { value, isTouching, _ in
                if isTouching == false {
                    isTouching = true
                    Task { [point = value.location] in
                        try await Task.sleep(for: .seconds(0.6))
                        
                        guard self.isTouching else { return }
                        manualFocusMode = .manualFocusLocking
                        manualFocusIndicatorPosition = point
                        setAutoFocus(at: point)
                        
                        try await Task.sleep(for: .seconds(0.4))
                        guard self.isTouching else {
                            manualFocusMode = .manualFocus
                            camera.focusLocked = false
                            return
                        }
                        setLockedFocus(at: point)
                        camera.focusLocked = true
                    }
                }
            }
    }
    
    private func setAutoFocus(at point: CGPoint) {
        let pointOfInterest = camera.cameraPreview
            .preview
            .videoPreviewLayer
            .captureDevicePointConverted(fromLayerPoint: point)
        #if !targetEnvironment(simulator)
        camera.setManualFocus(
            pointOfInterst: pointOfInterest,
            focusMode: .autoFocus,
            exposureMode: .autoExpose
        )
        #endif
    }
    
    private func setLockedFocus(at point: CGPoint) {
        let pointOfInterest = camera.cameraPreview
            .preview
            .videoPreviewLayer
            .captureDevicePointConverted(fromLayerPoint: point)
        #if !targetEnvironment(simulator)
        camera.setManualFocus(
            pointOfInterst: pointOfInterest,
            focusMode: .locked,
            exposureMode: .locked
        )
        #endif
    }
}
#endif
