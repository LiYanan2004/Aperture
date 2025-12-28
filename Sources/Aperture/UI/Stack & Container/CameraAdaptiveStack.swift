//
//  CameraAdaptiveStack.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import SwiftUI

/// A view that dynamically switches layout statck based on device context.
public struct CameraAdaptiveStack<Content: View>: View {
    /// The camera view model.
    public var camera: Camera
    /// A value indicates the distance between adjacent subviews.
    public var spacing: CGFloat?
    @ViewBuilder var content: (CameraAdaptiveStackProxy) -> Content

    /// Creates a view that dynamically switches layout statck based on device context.
    public init(
        camera: Camera,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (CameraAdaptiveStackProxy) -> Content
    ) {
        self.camera = camera
        self.spacing = spacing
        self.content = content
    }
    
    @State private var fallbackRotationAngle: CGFloat = 90 // default to potrait mode
    @Cancellables private var interfaceOrientationObservers
    
    public var body: some View {
        let cameraLayoutProxy = CameraAdaptiveStackProxy(
            interfaceRotationAngle: camera.previewRotationAngle ?? fallbackRotationAngle
        )
        _VariadicView.Tree(
            _CameraStack(
                alignment: cameraLayoutProxy.primaryLayoutStack.stack == .zstack ? .trailing : .center,
                spacing: spacing,
                configuration: cameraLayoutProxy.primaryLayoutStack
            )
        ) {
            content(cameraLayoutProxy)
        }
        #if canImport(UIKit)
        .onChange(of: camera.previewRotationAngle == nil, initial: true) {
            $interfaceOrientationObservers.cancelAll()
            
            let usesFallback = camera.previewRotationAngle == nil
            if usesFallback {
                _observeInterfaceOrientation()
            }
        }
        #endif
    }
    
    #if canImport(UIKit)
    private func _observeInterfaceOrientation() {
        let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .filter({ $0.activationState != .unattached })
            .sorted(by: { $0.activationState.rawValue < $1.activationState.rawValue }) // more active scenes go first
            .first
        guard let scene else { return }
        
        withValueObservation(
            of: scene,
            keyPath: \.effectiveGeometry,
            cancellables: &interfaceOrientationObservers
        ) {
            fallbackRotationAngle = switch $0.interfaceOrientation {
                case .portraitUpsideDown:
                    270
                case .landscapeLeft:
                    180
                case .landscapeRight:
                    0
                default:
                    90
            }
        }
    }
    #endif
}

