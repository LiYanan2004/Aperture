import SwiftUI
import AVFoundation

/// A view that holds a camera object and enables you to build a fully customized camera experience.
@available(visionOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct CameraView<Content: View>: View {
    @ViewBuilder var content: (Camera) -> Content
    
    @Environment(\._captureConfiguration) private var configuration
    @State private var camera = Camera()
    @State private var grantedPermission = false
    
    /// Creates a customized camera experience.
    /// - Parameter content: The view builder that creates a customized camera experience.
    public init(
        @ViewBuilder content: @escaping (Camera) -> Content
    ) {
        self.content = content
    }
    
    public var body: some View {
        content(camera)
            .environment(camera)
            .sensoryFeedback(.selection, trigger: camera.cameraSide)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black, ignoresSafeAreaEdges: .all)
            .environment(\.colorScheme, .dark)
            .disabled(!grantedPermission)
            .task {
                #if !targetEnvironment(simulator)
                grantedPermission = await camera.grantedPermission
                camera.configuration = configuration
                camera.startSession()
                #endif
            }
            .onChange(of: configuration) {
                camera.updateSession(with: configuration)
            }
            .onDisappear(perform: camera.stopSession)
    }
}

#if !os(watchOS) && !os(visionOS)
#Preview {
    CameraView { camera in
        VStack {
            ViewFinder()
            ShutterButton { capturedPhoto in
                // Process captured photo here.
            }
        }
    }
}
#endif
