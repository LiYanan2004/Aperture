//
//  CameraFlipButton.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import SwiftUI

/// A button that flips your camera view.
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS 17.0, tvOS 17.0, *)
public struct CameraFlipButton<Label: View>: View {
    public var camera: Camera
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
            guard let builtInCamera = camera.device as? any BuiltInCamera else { return }
            let newPosition = builtInCamera.position.flipped
            camera.device = AutomaticCamera(position: newPosition)
            self.position = newPosition
        } label: {
            label
        }
        .sensoryFeedback(.selection, trigger: position)
    }
}

@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS 17.0, tvOS 17.0, *)
extension CameraFlipButton {
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - titleKey: A title generated from a localized string. This is for accessibility.
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(titleKey, systemImage: systemImage)
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - titleKey: A title generated from a localized string. This is for accessibility.
    public init(
        _ titleKey: LocalizedStringKey,
        image: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(titleKey, image: image)
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - titleKey: A title generated from a localized string. This is for accessibility.
    public init(
        _ titleKey: LocalizedStringKey,
        image: ImageResource,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(titleKey, image: image)
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - title: A string used as the label’s title. This is for accessibility.
    public init(
        _ title: String,
        systemImage: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(title, systemImage: systemImage)
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - title: A string used as the label’s title. This is for accessibility.
    public init(
        _ title: String,
        image: String,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(title, image: image)
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - title: A string used as the label’s title. This is for accessibility.
    public init(
        _ title: String,
        image: ImageResource,
        camera: Camera
    ) where Label == SwiftUI.Label<Text, Image> {
        self.camera = camera
        self.label = SwiftUI.Label(title, image: image)
    }
}
