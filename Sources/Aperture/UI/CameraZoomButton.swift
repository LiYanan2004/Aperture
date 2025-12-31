//
//  CameraZoomButton.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/27.
//

import SwiftUI

/// A button that sets the video zoom level with custom animation curve when tapped.
@available(macOS, unavailable)
public struct CameraZoomButton<Label: View>: View {
    /// The camera view model.
    public let camera: Camera
    /// The target video zoom factor to ramp to when the button is tapped.
    public var zoomFactor: CGFloat
    /// The animation curve which interpolates the intermediate zoom factor during ramping.
    public var animation: Animation? = .smooth
    /// The label of this button.
    @ViewBuilder public var label: Label
    
    /// Creates a button that ramps the video zoom factor with animation when tapped.
    public init(
        camera: Camera,
        zoomFactor: CGFloat,
        animation: Animation? = .default,
        @ViewBuilder label: () -> Label
    ) {
        self.camera = camera
        self.zoomFactor = zoomFactor
        self.label = label()
    }
    
    public var body: some View {
        CameraZoomReader(camera: camera) { proxy in
            Button {
                proxy.zoom(toVideoZoomFactor: zoomFactor, animation: animation)
            } label: {
                label
            }
        }
    }
}

@available(macOS, unavailable)
extension CameraZoomButton where Label == Text {
    /// Creates a button that ramps the video zoom factor with animation when tapped.
    public init(camera: Camera, zoomFactor: CGFloat, animation: Animation? = .default) {
        self.init(camera: camera, zoomFactor: zoomFactor, animation: animation) {
            Text("\(zoomFactor * camera.displayZoomFactorMultiplier, format: .number.precision(.fractionLength(0...1)))x")
        }
    }
}

@available(macOS, unavailable)
#Preview {
    let camera = Camera(device: .builtInRearCamera, profile: .photo())
    let zoomFactors = [1.0] + [2.0, 10.0] /* (camera.device.captureDevice?
        .virtualDeviceSwitchOverVideoZoomFactors
        .compactMap({ $0 as? CGFloat }) ?? []) */
    
    HStack(spacing: 0) {
        ForEach(zoomFactors, id: \.self) { factor in
            CameraZoomButton(
                camera: camera,
                zoomFactor: factor
            )
        }
    }
    .buttonStyle(.bordered)
    .buttonBorderShape(.circle)
    .foregroundStyle(.primary)
    .padding(8)
    .background(.fill.quaternary, in: .capsule)
}
