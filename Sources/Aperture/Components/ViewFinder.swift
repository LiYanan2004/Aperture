import SwiftUI

/// A view that represents the current scene captured from the camera sensor.
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct ViewFinder: View {
    var includingOpticalZoomButtons: Bool
    
    @Environment(Camera.self) private var camera
    @Environment(\.deviceType) private var deviceType
    private var isPhone: Bool { deviceType == .phone }
    
    /// Create a view finder for camera experience.
    /// - parameter includingOpticalZoomButtons: Adds optical zoom factor buttons to indicate current zoom factor and provide quick zooming. Only shows on iOS.
    /// - note: This view must be installed inside a ``CameraView``.
    public init(includingOpticalZoomButtons: Bool = false) {
        self.includingOpticalZoomButtons = includingOpticalZoomButtons
    }
    
    public var body: some View {
        #if os(watchOS) || os(visionOS)
        fatalError("Current Operating System doesn't support ViewFinder.")
        #else
        @Bindable var camera = camera
        camera.cameraPreview
            .blur(radius: camera.sessionState == .running ? 0 : 15, opaque: true)
            #if targetEnvironment(simulator)
            .overlay {
                Rectangle().fill(.fill)
            }
            #endif
            .cameraPreviewFlip(trigger: camera.cameraSide)
            .rotation3DEffect(
                .degrees(camera.sessionState == .running && camera.isFrontCamera ? 180 : 0),
                axis: (x: 0.0, y: 1.0, z: 0.0),
                perspective: 0
            )
            #if os(iOS) || os(tvOS)
            .cameraFocusable()
            .cameraZoomFactor()
            #endif
            .opacity(1 - camera.dimCameraPreview)
            .layoutPriority(1)
            .overlay(alignment: .bottomLeading) {
                if camera.macroControlVisible {
                    Toggle(isOn: $camera.autoSwitchToMacroLens) {
                        Image(systemName: "camera.macro")
                            .symbolVariant(.slash)
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.responsive)
                    .padding(8)
                    .background(.black.opacity(0.5), in: .circle)
                    .padding(12)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }
            }
            #if os(iOS)
            .overlay(alignment: isPhone ? .bottom : .leading) {
                if includingOpticalZoomButtons {
                    CameraOpticalZoomOptionsBox().padding()
                }
            }
            #endif
            .overlay {
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
        #endif
    }
}
