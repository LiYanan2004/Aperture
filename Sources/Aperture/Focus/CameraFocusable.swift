import SwiftUI
import AVFoundation

extension View {
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    func cameraFocusable() -> some View {
        #if os(iOS) || os(tvOS)
        modifier(CameraFocusableModifier())
        #else
        self
        #endif
    }
}

#if os(iOS) || os(tvOS)
@available(macOS, unavailable)
struct CameraFocusableModifier: ViewModifier {
    @State private var showAutoFocusRectangle = false
    @State private var manualFocusRectanglePosition: CGPoint?
    @Environment(Camera.self) private var camera
    
    @GestureState private var isTouching = false
    @State private var manualFocusMode = FocusRectangle.FocusMode.manualFocus
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if let manualFocusRectanglePosition {
                    GeometryReader { previewProxy in
                        FocusRectangle(focusMode: manualFocusMode)
                            .frame(width: 75, height: 75)
                            .position(manualFocusRectanglePosition)
                            .id("focus rectangle at (\(manualFocusRectanglePosition.x), \(manualFocusRectanglePosition.y))")
                    }
                }
            }
            .overlay {
                if showAutoFocusRectangle {
                    FocusRectangle(focusMode: .autoFocus)
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
                manualFocusRectanglePosition = nil
                showAutoFocusRectangle = true
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    withAnimation {
                        showAutoFocusRectangle = false
                    }
                }
            }
            .onChange(of: camera.sessionState) {
                if camera.sessionState == .committing {
                    manualFocusRectanglePosition = nil
                }
            }
    }
    
    var autoFocusGesture: some Gesture {
        SpatialTapGesture()
            .onEnded {
                camera.focusLocked = false
                manualFocusMode = .manualFocus
                manualFocusRectanglePosition = $0.location
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
                        manualFocusRectanglePosition = point
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
