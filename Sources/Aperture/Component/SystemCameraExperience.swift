import SwiftUI

/// A system-like, pre-built camera experience.
///
/// This view is only for iOS and iPadOS. It doesn't support macOS.
/// - note: If your app supports multiple orientation,  ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to obtain correct behavior.
@available(macCatalyst, unavailable)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(iOS 17.0, tvOS 17.0, *)
public struct SystemCameraExperience: View {
    var action: (CapturedPhoto) -> Void
    @Environment(Camera.self) private var camera
    
    @Namespace private var namespace
    @Environment(\.deviceType) private var deviceType
    private var isPhone: Bool { deviceType == .phone }
    
    /// Create an automatic capture experience which is similar to system camera.
    /// - parameter action: The action to perform when captured photo arrives.
    /// - note: This view must be installed inside a ``CameraView``.
    public init(action: @escaping (CapturedPhoto) -> Void) {
        self.action = action
    }
    
    public var body: some View {
        if isPhone {
            iPhoneCameraExperience
        } else {
            iPadCameraExperience
        }
    }
    
    @ViewBuilder
    private var iPhoneCameraExperience: some View {
        GeometryReader { proxy in
            let fullHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            let compact = fullHeight < 700
            
            VStack(spacing: compact ? 8 : 12) {
                VStack(spacing: compact ? 0 : 12) {
                    statusBar
                    if compact == false {
                        AEAndAFLockedText
                    }
                    ViewFinder(includingOpticalZoomButtons: true)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .clipped()
                        .overlay(alignment: .top) {
                            if compact {
                                AEAndAFLockedText.padding(8)
                            }
                        }
                }
                photoText
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                ShutterButton(action: action)
                    .frame(maxWidth: compact ? 68 : .infinity)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .trailing) { cameraSwitchButton }
                    .padding(.horizontal, 20)
            }
            .ignoresSafeArea(edges: fullHeight < 700 ? .top : [])
            .dynamicTypeSize(.large ... .xxLarge)
        }
    }
    
    private var iPadCameraExperience: some View {
        ViewFinder(includingOpticalZoomButtons: true)
            .overlay(alignment: .top) {
                AEAndAFLockedText.padding(32)
            }
            .overlay(alignment: .trailing) {
                ShutterButton(action: action)
                    .padding(.vertical, 40)
                    .matchedGeometryEffect(id: "shutter_top", in: namespace, properties: .position, anchor: .top)
                    .matchedGeometryEffect(id: "shutter_bottom", in: namespace, properties: .position, anchor: .bottom)
                    .padding(.horizontal)
            }
            .overlay {
                VStack(spacing: 40) {
                    statusBar
                    cameraSwitchButton
                }
                .matchedGeometryEffect(id: "shutter_top", in: namespace, properties: .position, anchor: .bottom, isSource: false)
                
                VStack(spacing: 40) {
                    //photoAlbum
                    photoText
                }
                .matchedGeometryEffect(id: "shutter_bottom", in: namespace, properties: .position, anchor: .top, isSource: false)
            }
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var statusBar: some View {
        if isPhone {
            Color.clear
                .frame(height: 32)
                .overlay(alignment: .leading) {
                    FlashLightIndicator()
                        .padding(.horizontal, 12)
                }
        } else {
            Color.clear
                .frame(maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    FlashLightIndicator()
                }
        }
    }
    
    private var AEAndAFLockedText: some View {
        Text("AF/AE Locked")
            .font(.subheadline)
            .padding(4)
            .padding(.horizontal, 8)
            .background(.yellow, in: .rect(cornerRadius: 5))
            .foregroundStyle(.black)
            .animation(.smooth) { content in
                content.opacity(camera.focusLocked ? 1 : 0)
            }
    }
    
    private var cameraSwitchButton: some View {
        CameraSwitcher()
            .padding(12)
            .background(
                isPhone ? AnyShapeStyle(.fill.tertiary) : AnyShapeStyle(.black.tertiary),
                in: .circle
            )
    }
    
    private var photoText: some View {
        Text("PHOTO")
            .font(.subheadline)
            .foregroundStyle(.yellow)
    }
}

#if os(iOS) && !targetEnvironment(macCatalyst)
#Preview {
    CameraView { camera in
        SystemCameraExperience { capturedPhoto in
            
        }
    }
}
#endif
