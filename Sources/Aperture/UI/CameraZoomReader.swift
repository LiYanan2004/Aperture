//
//  CameraZoomReader.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/27.
//

import SwiftUI

/// A view that provides programmatic camera zooming with custom animation curve, by working with a proxy.
@available(macOS, unavailable)
public struct CameraZoomReader<Content: View>: View {
    /// The camera view model.
    public let camera: Camera
    /// The view builder that creates the reader's content.
    @ViewBuilder var content: (CameraZoomProxy) -> Content
    
    /// Creates an instance that can programmatically control camera zoom factor.
    public init(
        camera: Camera,
        @ViewBuilder content: @escaping (CameraZoomProxy) -> Content
    ) {
        self.camera = camera
        self.content = content
    }
    
    @State private var nextZoomFactor: CGFloat = 1.0

    public var body: some View {
        content(
            CameraZoomProxy {
                #if os(iOS)
                nextZoomFactor = camera.zoomFactor
                #endif
            } updateZoomFactor: {
                nextZoomFactor = $0
            }
        )
        .modifier(_CameraZoomModifier(camera: camera, nextZoomFactor: nextZoomFactor))
    }
}

// MARK: - Proxy

/// A proxy object that provides programmatic camera zooming with custom animation curve.
public struct CameraZoomProxy {
    private var syncZoomFactor: () -> Void
    private var updateZoomFactor: (CGFloat) -> Void
    
    /// Create an instance that can provide programmatic video capture device zooming.
    fileprivate init(
        syncZoomFactor: @escaping () -> Void,
        updateZoomFactor: @escaping (CGFloat) -> Void
    ) {
        self.syncZoomFactor = syncZoomFactor
        self.updateZoomFactor = updateZoomFactor
    }
    
    /// Programmatically perform a camera zoom factor ramping with animation provided.
    /// - parameter factor: Target zoom factor level.
    /// - parameter animation: The animation used during the ramp.
    @available(macOS, unavailable)
    public func zoom(toVideoZoomFactor factor: CGFloat, animation: Animation? = .default) {
        #if os(iOS)
        syncZoomFactor()
        withAnimation(animation) {
            updateZoomFactor(factor)
        }
        #endif
    }
}

// MARK: - Animatable Modifier

@available(macOS, unavailable)
fileprivate struct _CameraZoomModifier: ViewModifier, Animatable {
    let camera: Camera
    var nextZoomFactor: CGFloat
    
    var animatableData: CGFloat {
        get { nextZoomFactor }
        set {
            // `newValue` is the interpolation of intermediate value (according to the animation curve) or the final value.
            nextZoomFactor = newValue
            #if os(iOS)
            camera.zoomFactor = newValue
            #endif
        }
    }
    
    func body(content: Content) -> some View {
        // We don't modify the body.
        // We only leverage the `animatableData` to produce intermediate values.
        content
    }
}
