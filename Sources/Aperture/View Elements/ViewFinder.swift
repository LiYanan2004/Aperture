import SwiftUI

/// A view that represents the current scene captured from the camera sensor.
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct ViewFinder: CameraControl {
    public enum AspectRatio: Sendable {
        /// 4:3 aspect ratio.
        case fourByThree
        /// 16:9 aspect ratio.
        case sixteenByNine
        /// 1:1 aspect ratio.
        case square
        /// Custom aspect ratio.
        case custom(CGFloat)
        
        var portraitAspectRatio: CGFloat {
            switch self {
            case .fourByThree: 3 / 4
            case .sixteenByNine: 9 / 16
            case .square: 1
            case .custom(let aspectRatio): aspectRatio
            }
        }
        
        var landscapeAspectRatio: CGFloat {
            1 / portraitAspectRatio
        }
    }
    var aspectRatio: AspectRatio
    var includingOpticalZoomButtons: Bool
    
    @Environment(\.deviceType) private var deviceType
    private var isPhone: Bool { deviceType == .phone }
    
    /// Create a view finder for camera experience.
    /// - parameter includingOpticalZoomButtons: Adds optical zoom factor buttons to indicate current zoom factor and provide quick zooming. These buttons are only shown on iOS.
    /// - note: This view must be installed inside a ``Camera``.
    public init(
        aspectRatio: AspectRatio = .fourByThree,
        includingOpticalZoomButtons: Bool = true
    ) {
        self.aspectRatio = aspectRatio
        self.includingOpticalZoomButtons = includingOpticalZoomButtons
    }
    
    public func makeBody(_ camera: CameraManager) -> some View {
        @Bindable var camera = camera
        camera.cameraPreview
            .aspectRatio(aspectRatio.portraitAspectRatio, contentMode: .fit) // FIXME: Only respect portrait aspect ratio.
            .sensoryFeedback(.selection, trigger: camera.cameraSide)
            .blur(radius: camera.sessionState == .running ? 0 : 15, opaque: true)
            #if targetEnvironment(simulator)
            .overlay {
                Rectangle().fill(.fill)
            }
            #endif
            .cameraPreviewFlipEffect(trigger: camera.cameraSide)
            .rotation3DEffect(
                .degrees(camera.sessionState == .running && camera.isFrontCamera ? 180 : 0),
                axis: (x: 0.0, y: 1.0, z: 0.0),
                perspective: 0
            )
            #if os(iOS) || os(tvOS)
            .allowsTapToFocus()
            .allowsCameraZooming()
            #endif
            .opacity(1 - camera.dimCameraPreview)
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
                    CameraZoomLevelPicker().padding()
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
    }
}

#Preview {
    Camera {
        ViewFinder()
    }
}
