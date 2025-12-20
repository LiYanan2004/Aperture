//
//  OpticalZoomButtonGroup.swift
//  Aperture
//
//  Created by Yanan Li on 2025/6/3.
//

import SwiftUI

struct OpticalZoomButtonGroup: View {
    var body: some View {
        _Legacy_CameraReader { proxy in
            switch proxy.position {
                case .back:
                    HStack(spacing: 16) {
                        ForEach(proxy._cameraManager.backCameraOpticalZoomRanges, id: \.self) { range in
                            OpticalZoomButton(zoomRange: range)
                        }
                    }
                    .padding(8)
                    .background(
                        .black.quaternary.opacity(
                            proxy._cameraManager.backCameraOpticalZoomRanges.isEmpty ? 0 : 1
                        ),
                        in: .capsule
                    )
                    .dynamicTypeSize(
                        DynamicTypeSize.small...DynamicTypeSize.xxLarge
                    )
                    .cameraSmoothZoomEffect(
                        proxy._cameraManager.backCameraDisplayZoomFactor,
                        isEnabled: proxy.zoomFactor != proxy._cameraManager.backCameraDisplayZoomFactor
                    )
                case .front:
                    Button {
                        proxy.zoomFactor = proxy.zoomFactor > 1 ? 1 : 1.3
                    } label: {
                        let symbolName = if proxy.zoomFactor == 1 {
                            "arrow.down.right.and.arrow.up.left"
                        } else {
                            "arrow.up.left.and.arrow.down.right"
                        }
                        Image(systemName: symbolName)
                            .padding(12)
                            .background(.black.secondary, in: .circle)
                    }
                    .rotationEffect(proxy.interfaceRotationAngle)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.responsive)
    }
}
