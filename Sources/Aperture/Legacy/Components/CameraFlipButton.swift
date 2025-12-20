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
    @ViewBuilder var label: () -> Label
    
    /// Create a button that switches between rear camera and front camera.
    /// - note: This view must be installed inside a ``Camera``.
    public init() where Label == SwiftUI.Label<Text, Image> {
        self.label = {
            SwiftUI.Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
        }
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - note: This view must be installed inside a ``Camera``.
    public init(@ViewBuilder _ label: @escaping () -> Label) {
        self.label = label
    }

    public var body: some View {
        _Legacy_CameraReader { proxy in
            Button {
                withAnimation(.easeInOut) {
                    proxy.position.toggle()
                }
            } label: {
                label()
            }
            .labelStyle(.iconOnly)
            .imageScale(.large)
            .buttonStyle(.responsive)
            .rotationEffect(proxy.interfaceRotationAngle)
        }
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
    /// - note: This view must be installed inside a ``Camera``.
    public init(_ titleKey: LocalizedStringKey, systemImage: String) where Label == SwiftUI.Label<Text, Image> {
        self.label = {
            SwiftUI.Label(titleKey, systemImage: systemImage)
        }
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - titleKey: A title generated from a localized string. This is for accessibility.
    /// - note: This view must be installed inside a ``Camera``.
    public init(_ titleKey: LocalizedStringKey, image: String) where Label == SwiftUI.Label<Text, Image> {
        self.label = {
            SwiftUI.Label(titleKey, image: image)
        }
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - titleKey: A title generated from a localized string. This is for accessibility.
    /// - note: This view must be installed inside a ``Camera``.
    public init(_ titleKey: LocalizedStringKey, image: ImageResource) where Label == SwiftUI.Label<Text, Image> {
        self.label = {
            SwiftUI.Label(titleKey, image: image)
        }
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - title: A string used as the label’s title. This is for accessibility.
    /// - note: This view must be installed inside a ``Camera``.
    public init(_ title: String, systemImage: String) where Label == SwiftUI.Label<Text, Image> {
        self.label = {
            SwiftUI.Label(title, systemImage: systemImage)
        }
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - title: A string used as the label’s title. This is for accessibility.
    /// - note: This view must be installed inside a ``Camera``.
    public init(_ title: String, image: String) where Label == SwiftUI.Label<Text, Image> {
        self.label = {
            SwiftUI.Label(title, image: image)
        }
    }
    
    /// Create a button that switches between rear camera and front camera.
    /// - parameters:
    ///     - title: A string used as the label’s title. This is for accessibility.
    /// - note: This view must be installed inside a ``Camera``.
    public init(_ title: String, image: ImageResource) where Label == SwiftUI.Label<Text, Image> {
        self.label = {
            SwiftUI.Label(title, image: image)
        }
    }
}

@available(macOS, unavailable)
#Preview {
    CameraView {
        CameraFlipButton {
            Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
                .labelStyle(.titleAndIcon)
        }
    }
}
