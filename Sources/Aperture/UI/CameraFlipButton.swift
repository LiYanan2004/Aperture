//
//  CameraFlipButton.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import SwiftUI

/// A button that flips built-in capture device between front and rear camera.
@available(macOS, unavailable)
public struct CameraFlipButton<Label: View>: View {
    /// The camera view model.
    public var camera: Camera
    /// The label of flip button.
    @ViewBuilder public var label: Label
    
    @State private var position: CameraPosition?
    
    /// Create a button that switches between rear camera and front camera.
    public init(camera: Camera) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
    }
    
    /// Create a button that switches between rear camera and front camera.
    public init(camera: Camera, @ViewBuilder _ label: @escaping () -> Label) {
        self.camera = camera
        self.label = label()
    }

    public var body: some View {
        Button {
            guard let cameraPosition = camera.device.position else { return }
            let newPosition = cameraPosition.flipped
            
            switch camera.device {
                case _ as BuiltInCamera:
                    camera.device = BuiltInCamera(position: newPosition)
                case _ as WideAngleCamera:
                    camera.device = WideAngleCamera(position: newPosition)
                default:
                    return
            }
            
            self.position = newPosition
        } label: {
            label
        }
        .sensoryFeedback(.selection, trigger: position)
        .disabled(!(camera.device is BuiltInCamera || camera.device is WideAngleCamera))
    }
}

@available(macOS, unavailable)
@available(iOS 17.0, *)
extension CameraFlipButton {
    /// Create a button that switches between rear camera and front camera.
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(titleKey, systemImage: systemImage)
    }
    
    /// Create a button that switches between rear camera and front camera.
    public init(
        _ titleKey: LocalizedStringKey,
        image: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(titleKey, image: image)
    }
    
    /// Create a button that switches between rear camera and front camera.
    public init(
        _ titleKey: LocalizedStringKey,
        image: ImageResource,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(titleKey, image: image)
    }
    
    /// Create a button that switches between rear camera and front camera.
    public init(
        _ title: String,
        systemImage: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(title, systemImage: systemImage)
    }
    
    /// Create a button that switches between rear camera and front camera.
    public init(
        _ title: String,
        image: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(title, image: image)
    }
    
    /// Create a button that switches between rear camera and front camera.
    public init(
        _ title: String,
        image: ImageResource,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(title, image: image)
    }
}
