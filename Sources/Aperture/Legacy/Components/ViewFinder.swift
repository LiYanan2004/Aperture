import SwiftUI
import CoreMedia

/// A view that represents the current scene captured from the camera sensor.
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct ViewFinder: View {
    @Environment(\.zoomInteractionFlag) private var zoomInteractionFlag
    @Environment(\.focusAndExposureAdjustmentInteractionFlag) private var focusAndExposureAdjustmentInteractionFlag
    private var deviceType: DeviceType {
        ProcessInfo.processInfo.deviceType
    }
    private var isPhone: Bool { deviceType == .phone }
    
    public init() { }
    
    public var body: some View {
        _Legacy_CameraReader { proxy in
            Rectangle()
                .fill(.clear)
                .overlay { proxy._cameraManager.cameraPreview }
                .transaction { transcation in
                    transcation.disablesAnimations = true
                    transcation.animation = nil
                }
                .blur(radius: proxy._cameraManager.sessionState == .running ? 0 : 15, opaque: true)
                .overlay { cornerBorders }
                .sensoryFeedback(.selection, trigger: proxy.position)
                #if targetEnvironment(simulator)
                .overlay {
                    Rectangle().fill(.fill)
                }
                #endif
                .rotation3DEffect(
                    .degrees(proxy._cameraManager.sessionState == .running && proxy._cameraManager.isFrontCamera ? 180 : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0),
                    perspective: 0
                )
                .cameraPreviewFlipEffect(trigger: proxy.position)
                #if os(iOS)
                .allowsTapToFocus(focusAndExposureAdjustmentInteractionFlag == .enabled)
                .allowsCameraZooming(zoomInteractionFlag == .enabled)
                .overlay(alignment: isPhone ? .bottom : .leading) {
                    if zoomInteractionFlag == .enabled {
                        OpticalZoomButtonGroup()
                            .padding()
                    }
                }
                #endif
                .opacity(1 - proxy._cameraManager.dimCameraPreview)
        }
    }
    
    private var cornerBorders: some View {
        Rectangle()
            .stroke(.secondary, lineWidth: 2)
            .mask {
                ZStack {
                    Rectangle()
                        .frame(width: 28, height: 28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    Rectangle()
                        .frame(width: 28, height: 28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    
                    Rectangle()
                        .frame(width: 28, height: 28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    
                    Rectangle()
                        .frame(width: 28, height: 28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .opacity(isPhone ? 1 : 0)
    }
}

#Preview {
    CameraView {
        ViewFinder()
    }
}
