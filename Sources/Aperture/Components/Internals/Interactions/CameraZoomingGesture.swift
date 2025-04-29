import SwiftUI

extension View {
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    @ViewBuilder
    func allowsCameraZooming(_ flag: Bool = true) -> some View {
        if flag {
            modifier(_CameraZoomingGestureModifier())
        } else {
            self
        }
    }
}

struct _CameraZoomingGestureModifier: ViewModifier {
    @State private var initialFactor: CGFloat?
    @Environment(Camera.self) private var camera
    
    private var minZoomFactor: CGFloat {
        #if os(iOS)
        camera.videoDevice?.minAvailableVideoZoomFactor ?? 1
        #else
        1
        #endif
    }
    private var maxZoomFactor: CGFloat {
        #if os(iOS)
        5.0 * CGFloat(truncating: camera.videoDevice?.virtualDeviceSwitchOverVideoZoomFactors.last ?? 1)
        #else
        1
        #endif
    }
    
    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .simultaneousGesture(zoomGesture)
            #endif
    }
    
    #if os(iOS)
    @MainActor
    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if initialFactor == nil {
                    do {
                        try camera.videoDevice?.lockForConfiguration()
                        self.initialFactor = camera.videoDevice?.videoZoomFactor ?? 1
                    } catch {
                        camera.logger.error("Zoom gesture failed: \(error.localizedDescription)")
                    }
                }
                guard let initialFactor else { return }
                
                // Toggle between 12MP and 8MP for front camera
                if !camera.isBackCamera {
                    camera.setZoomFactor(
                        value.magnification > 1 ? 1.3 : 1,
                        withRate: 5000
                    )
                    return
                }
                
                let zoomFactor = min(max(minZoomFactor, initialFactor * (value.magnification)), maxZoomFactor)
                camera.setZoomFactor(zoomFactor, animation: nil)
            }
            .onEnded { _ in
                camera.videoDevice?.unlockForConfiguration()
                initialFactor = nil
            }
    }
    #endif
}
