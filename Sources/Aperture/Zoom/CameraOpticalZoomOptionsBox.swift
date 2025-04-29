#if os(iOS)
import SwiftUI

struct CameraOpticalZoomOptionsBox: View {
    @State private var showDefault = true
    @Environment(Camera.self) private var model
    private var backCameraOpticalFactors: [CGFloat] {
        model.backCameraOpticalZoomFactors
    }
    
    var body: some View {
        ZStack {
            if model.isBackCamera {
                opticalZoomButtonForBackCamera
                    .transition(.opacity.animation(.smooth(duration: 0.2)))
            } else if model.frontCameraDefaultZoomFactor != 1 {
                zoomButtonForFrontCamera
                    .transition(.opacity.animation(.smooth(duration: 0.2)))
            }
        }
        .task(id: model.sessionState) {
            showDefault = model.sessionState == .running ? false : true
        }
    }
    
    private var zoomButtonForFrontCamera: some View {
        Button {
            model.setZoomFactor(model.zoomFactor > 1 ? 1 : 1.3, withRate: 5000)
        } label: {
            let symbolName = if model.zoomFactor > 1 || showDefault {
                "arrow.up.left.and.arrow.down.right"
            } else {
                "arrow.down.right.and.arrow.up.left"
            }
            Image(systemName: symbolName)
                .padding(12)
                .background(.black.secondary, in: .circle)
        }
        .buttonStyle(.responsive)
        .rotationEffect(.degrees(model.interfaceRotationAngle))
        .onAppear { showDefault = true }
    }
    
    private var opticalZoomButtonForBackCamera: some View {
        HStack(spacing: 16) {
            CameraOpticalZoomOptionButton(
                targetZoomFactor: 1,
                activeZoomFactorRange: 1 ..< (backCameraOpticalFactors.first ?? 5),
                defaultSelection: 1 == model.backCameraDefaultZoomFactor,
                showDefault: showDefault
            )
            .rotationEffect(.degrees(model.interfaceRotationAngle))
            
            ForEach(Array(backCameraOpticalFactors.enumerated()), id: \.1.self) { (i, factor) in
                let range = if i + 1 > backCameraOpticalFactors.count - 1 {
                    factor ..< .infinity
                } else {
                    factor ..< backCameraOpticalFactors[i + 1]
                }
                CameraOpticalZoomOptionButton(
                    targetZoomFactor: factor,
                    activeZoomFactorRange: range,
                    defaultSelection: factor == model.backCameraDefaultZoomFactor,
                    showDefault: showDefault
                )
                .rotationEffect(.degrees(model.interfaceRotationAngle))
            }
        }
        .padding(8)
        .background(
            .black.quaternary.opacity(
                backCameraOpticalFactors.isEmpty ? 0 : 1
            ),
            in: .capsule
        )
        .dynamicTypeSize(
            DynamicTypeSize.small...DynamicTypeSize.xxLarge
        )
        .onAppear { showDefault = true }
    }
}

struct CameraOpticalZoomOptionButton: View {
    var targetZoomFactor: CGFloat
    var activeZoomFactorRange: Range<CGFloat>
    var defaultSelection: Bool
    var showDefault: Bool
    
    @Environment(Camera.self) private var model
    @ScaledMetric(relativeTo: .headline) private var size = 28
    private var currentZoomFactor: CGFloat {
        #if targetEnvironment(simulator)
        4.4
        #else
        if showDefault && defaultSelection {
            return model.backCameraDefaultZoomFactor
        }
        return model.zoomFactor
        #endif
    }
    private var isActive: Bool {
        if showDefault {
            return defaultSelection
        }
        return currentZoomFactor >= activeZoomFactorRange.lowerBound && currentZoomFactor < activeZoomFactorRange.upperBound
    }
    private var displayTargetZoomFactor: CGFloat {
        targetZoomFactor / model.backCameraDefaultZoomFactor
    }
    private var displayZoomFactor: CGFloat {
        #if targetEnvironment(simulator)
        2.2
        #else
        currentZoomFactor / model.backCameraDefaultZoomFactor
        #endif
    }
    
    var body: some View {
        Button {
            model.setZoomFactor(targetZoomFactor, withRate: 50)
        } label: {
            Circle()
                .fill(.black.secondary)
                .frame(width: size)
                .scaleEffect(isActive ? 1.35 : 1)
                .overlay {
                    Group {
                        if isActive {
                            Text(
                                displayZoomFactor,
                                format: .number
                                    .rounded(rule: .down)
                                    .precision(.fractionLength(0...1))
                            )
                            +
                            Text("x")
                                .textScale(.secondary)
                        } else {
                            Text(displayTargetZoomFactor.formatted().suffix(2))
                        }
                    }
                    .fixedSize()
                    .kerning(0.2)
                    .font(.caption2)
                    .scaleEffect(isActive ? 1.2 : 1)
                    .fontWeight(isActive ? .semibold : .medium)
                    .foregroundStyle(isActive ? .yellow : .white)
                    .contentTransition(.interpolate)
                    .minimumScaleFactor(0.8)
                }
        }
        .buttonStyle(.responsive)
    }
}

#Preview {
    CameraOpticalZoomOptionsBox()
        .environment(Camera())
}
#endif
