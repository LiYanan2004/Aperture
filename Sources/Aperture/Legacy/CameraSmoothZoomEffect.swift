//
//  CameraSmoothZoomEffect.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/5/12.
//

import SwiftUI

struct CameraSmoothZoomEffect: AnimatableModifier {
    var zoom: CGFloat
    var isEnabled: Bool
    
    var animatableData: CGFloat {
        get { zoom }
        set { zoom = max(1, newValue) }
    }

    func body(content: Content) -> some View {
        _Legacy_CameraReader { proxy in
            content
                .onChange(of: zoom) {
                    guard isEnabled else { return }
                    
                    if zoom > 1 {
                        proxy._cameraManager.zoomFactor = zoom
                    }
                }
        }
    }
}

extension View {
    func cameraSmoothZoomEffect(
        _ factor: CGFloat,
        duration: TimeInterval = 0.55,
        isEnabled: Bool = true
    ) -> some View {
        animation(.smooth(duration: duration, extraBounce: 0.1)) { content in
            content.modifier(CameraSmoothZoomEffect(zoom: factor, isEnabled: isEnabled))
        }
    }
}
