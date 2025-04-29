import SwiftUI
import AVFoundation

/// A view that holds a camera object and enables you to build a fully customized camera experience.
@available(visionOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct CameraView<Content: View>: View {
    var errorHandler: ((_ error: CameraError) -> Void)?
    @ViewBuilder var content: (Camera) -> Content
    
    @Environment(\._captureConfiguration) private var configuration
    @State var camera = Camera()
    
    /// Creates a customized camera experience.
    /// - Parameters:
    ///     - errorHandler: The action to perform when error occurs.
    ///     - content: The view builder that creates a customized camera experience.
    public init(
        errorHandler: ((CameraError) -> Void)? = nil,
        @ViewBuilder content: @escaping (Camera) -> Content
    ) {
        self.errorHandler = errorHandler
        self.content = content
    }
    
    public var body: some View {
        content(camera)
            .environment(camera)
            .sensoryFeedback(.selection, trigger: camera.cameraSide)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black, ignoresSafeAreaEdges: .all)
            .environment(\.colorScheme, .dark)
            .task {
                #if !targetEnvironment(simulator)
                guard await camera.grantedPermission else {
                    errorHandler?(.permissionDenied)
                    return
                }
                camera.errorHandler = errorHandler
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
    CameraView { error in
        switch error {
        case .captureError(let error):
            print("Capture Error: \(error.localizedDescription)")
        case .permissionDenied:
            print("User denied camera permission")
        }
    } content: { camera in
        VStack {
            ViewFinder()
            ShutterButton { capturedPhoto in
                // Process captured photo here.
            }
        }
    }
}
#endif
