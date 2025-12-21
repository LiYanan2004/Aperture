//
//  ShutterButton.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI

/// A button that captures photo using current capture device.
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct CameraShutterButton: View {
    var camera: Camera
    var configuration: PhotoCaptureConfiguration
    var action: (CapturedPhoto) -> Void
    
    @State private var counter = 0
    
    /// Create a shutter button for photo capturing.
    /// - parameter action: The action to perform when captured photo arrives.
    /// - note: This view must be installed inside a ``Camera``.
    public init(
        camera: Camera,
        configuration: PhotoCaptureConfiguration = .init(),
        action: @escaping (CapturedPhoto) -> Void
    ) {
        self.camera = camera
        self.configuration = configuration
        self.action = action
    }
    
    public var body: some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                captureButton
                    .buttonStyle(.responsive(onPressingChanged: { _ in counter += 1 }))
                    .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: counter)
            }
            .background(.fill.secondary, in: .circle)
            .padding(6)
            .background {
                Circle()
                    .strokeBorder(.primary, lineWidth: 4)
            }
            .disabled(camera.shutterDisabled)
            .frame(maxWidth: 72)
    }
    
    private var captureButton: some View {
        Button {
            Task {
                let capturedPhoto = try await camera.takePhoto(configuration: configuration)
                action(capturedPhoto)
            }
        } label: {
            Circle()
                .opacity(camera.isBusyProcessing ? 0 : 1)
                .overlay {
                    ProgressView()
                        .progressViewStyle(.spinning)
                        .visualEffect { content, proxy in
                            content.scaleEffect((72.0 - 12.0) / proxy.size.width)
                        }
                        .foregroundStyle(.black)
                        .opacity(camera.isBusyProcessing ? 1 : 0)
                        .scaledToFill()
                }
                .animation(.smooth(duration: 0.15), value: camera.isBusyProcessing)
        }
    }
}

#Preview {
    CameraShutterButton(camera: Camera(device: .standard, configuration: .photo)) { photo in
        // Process captured photo here.
    }
}
