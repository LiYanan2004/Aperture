//
//  OpticalZoomButton.swift
//  Aperture
//
//  Created by Yanan Li on 2025/6/2.
//

import SwiftUI

struct OpticalZoomButton: View {
    var zoomRange: Range<CGFloat>
    private var opticalZoomFactor: CGFloat {
        zoomRange.lowerBound
    }
    
    var body: some View {
        _Legacy_CameraReader { proxy in
            let cameraManager = proxy._cameraManager
            let displayZoomFactor = cameraManager.backCameraDisplayZoomFactor
            let isActive = zoomRange.contains(displayZoomFactor)
            
            Button {
                proxy._cameraManager.backCameraDisplayZoomFactor = opticalZoomFactor
            } label: {
                Circle()
                    .fill(.black.secondary)
                    .frame(width: 28)
                    .scaleEffect(isActive ? 1.35 : 1)
                    .overlay {
                        Group {
                            if isActive {
                                Text(
                                    displayZoomFactor / cameraManager.backCameraDefaultZoomFactor,
                                    format: .number
                                        .rounded(rule: .down)
                                        .precision(.fractionLength(0...1))
                                )
                                +
                                Text(verbatim: "x")
                                    .textScale(.secondary)
                            } else {
                                let defaultZoomFactorDisplayText = (zoomRange.lowerBound / cameraManager.backCameraDefaultZoomFactor)
                                    .formatted(
                                        FloatingPointFormatStyle()
                                            .rounded(rule: .down)
                                            .precision(.fractionLength(0...1))
                                    )
                                Text(verbatim: defaultZoomFactorDisplayText)
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
}

#Preview {
    CameraView {
        OpticalZoomButton(zoomRange: 1.0..<2.0)
    }
}
