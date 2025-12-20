//
//  CameraAdaptiveStack.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import SwiftUI

public struct CameraAdaptiveStack<Content: View>: View {
    var session: CameraSession
    var spacing: CGFloat?
    @ViewBuilder var content: (CameraAdaptiveStackProxy) -> Content

    public init(
        session: CameraSession,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (CameraAdaptiveStackProxy) -> Content
    ) {
        self.session = session
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        let cameraLayoutProxy = CameraAdaptiveStackProxy(
            interfaceRotationAngle: session.previewRotationAngle
        )
        _VariadicView.Tree(
            _CameraStack(
                spacing: spacing,
                configuration: cameraLayoutProxy.primaryLayoutStack
            )
        ) {
            content(cameraLayoutProxy)
        }
    }
}

