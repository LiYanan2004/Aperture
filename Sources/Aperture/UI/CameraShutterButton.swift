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
    var session: PhotoCaptureSession
    var configuration: PhotoConfiguration
    var action: (CapturedPhoto) -> Void
    
    @State private var counter = 0
    
    /// Create a shutter button for photo capturing.
    /// - parameter action: The action to perform when captured photo arrives.
    /// - note: This view must be installed inside a ``Camera``.
    public init(
        session: PhotoCaptureSession,
        configuration: PhotoConfiguration = .init(),
        action: @escaping (CapturedPhoto) -> Void
    ) {
        self.session = session
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
            .disabled(session.shutterDisabled)
            .frame(maxWidth: 72)
    }
    
    private var captureButton: some View {
        Button {
            Task {
                try await action(
                    session.takeStillPhoto(
                        configuration: configuration
                    )
                )
            }
        } label: {
            Circle()
                .opacity(session.isBusyProcessing ? 0 : 1)
                .overlay {
                    ProgressView()
                        .progressViewStyle(.spinning)
                        .visualEffect { content, proxy in
                            content.scaleEffect((72.0 - 12.0) / proxy.size.width)
                        }
                        .foregroundStyle(.black)
                        .opacity(session.isBusyProcessing ? 1 : 0)
                        .scaledToFill()
                }
                .animation(.smooth(duration: 0.15), value: session.isBusyProcessing)
        }
    }
}

#Preview {
    CameraShutterButton(session: PhotoCaptureSession(camera: .standard)) { photo in
        // Process captured photo here.
    }
}
