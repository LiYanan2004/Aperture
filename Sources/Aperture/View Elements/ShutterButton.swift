import SwiftUI

/// A button that captures photo using current capture device.
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct ShutterButton: CameraControl {
    var action: (CapturedPhoto) -> Void
    
    @State private var counter = 0
    
    /// Create a shutter button for photo capturing.
    /// - parameter action: The action to perform when captured photo arrives.
    /// - note: This view must be installed inside a ``Camera``.
    public init(action: @escaping (CapturedPhoto) -> Void) {
        self.action = action
    }
    
    public func makeBody(_ camera: CameraManager) -> some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Button {
                    Task {
                        let capturedPhoto = try await camera.capturePhoto()
                        action(capturedPhoto)
                    }
                } label: {
                    Circle()
                        .fill(.white)
                        .opacity(camera.isBusyProcessing ? 0 : 1)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.spinning)
                                .visualEffect { content, proxy in
                                    content.scaleEffect((72.0 - 12.0) / proxy.size.width)
                                }
                                .foregroundStyle(.black)
                                .opacity(camera.isBusyProcessing ? 1 : 0)
                                .scaledToFill()
                        }
                        .animation(.smooth(duration: 0.15), value: camera.isBusyProcessing)
                }
                .buttonStyle(.responsive(onPressingChanged: { _ in counter += 1 }))
                .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: counter)
            }
            .background(.fill.secondary, in: .circle)
            .padding(6)
            .background {
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
            }
            .disabled(camera.shutterDisabled)
            .frame(maxWidth: 72)
    }
}

#Preview {
    Camera {
        ShutterButton { photo in
            // Process captured photo here.
        }
    }
}
