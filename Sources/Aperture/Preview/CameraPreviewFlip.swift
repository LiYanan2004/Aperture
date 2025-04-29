import SwiftUI

extension View {
    func cameraPreviewFlip<E: Equatable>(trigger: E) -> some View {
        modifier(CameraPreviewFlip(trigger: trigger))
    }
}

struct CameraPreviewFlip<E: Equatable>: ViewModifier {
    var trigger: E
    @State private var initial = CameraPreviewFlipKeyFrame.start
    
    func body(content: Content) -> some View {
        content
            .keyframeAnimator(
                initialValue: initial,
                trigger: trigger
            ) { content, frame in
                content
                    .scaleEffect(frame.scale)
                    .rotation3DEffect(
                        .degrees(frame.rotation3DAngle),
                        axis: (x: 0.0, y: 1.0, z: 0.0),
                        perspective: 0
                    )
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(0.9, duration: 0.2, spring: .smooth)
                    CubicKeyframe(1, duration: 0.2)
                }
                
                KeyframeTrack(\.rotation3DAngle) {
                    SpringKeyframe(initial == .start ? -180 : 0, duration: 0.4, spring: .smooth)
                }
            }
            .onChange(of: trigger) {
                self.initial = (initial == .start ? .end : .start)
            }
    }
}

fileprivate struct CameraPreviewFlipKeyFrame: Equatable {
    var rotation3DAngle: Double
    var scale: CGFloat
    
    static var start = CameraPreviewFlipKeyFrame(rotation3DAngle: 0, scale: 1)
    static var end = CameraPreviewFlipKeyFrame(rotation3DAngle: -180, scale: 1)
}
