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
    
    private let buttonSize: CGFloat = 68
    
    public var body: some View {
        PhotoCaptureButton(
            camera: camera,
            configuration: configuration,
            action: action
        )
        .adoptsProposedSize()
        .aspectRatio(1, contentMode: .fit)
        .frame(width: buttonSize)
        .disabled(camera.shutterDisabled)
    }
    
    struct CaptureError: LocalizedError {
        var _error: any Error
        
        var errorDescription: String? {
            _error.localizedDescription
        }
    }
}

extension CameraShutterButton {
    fileprivate struct PhotoCaptureButton: View {
        var camera: Camera
        var configuration: PhotoCaptureConfiguration
        var action: (CapturedPhoto) -> Void
        
        // The same size as system shutter button (from AVCam sample)
        private let lineWidth = CGFloat(4.0)
        
        @State private var counter = 0
        @State private var error: CaptureError?
        @State private var presentsErrorAlert = false
        
        var body: some View {
            GeometryReader { buttonProxy in
                let buttonSize = buttonProxy.size.width // assumes it has 1:1 aspect ratio
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: lineWidth)
                    Button(action: takePhoto) {
                        Circle()
                            .inset(by: lineWidth * 1.2)
                            .opacity(camera.isBusyProcessing ? 0.15 : 1)
                            .overlay {
                                ProgressView()
                                    .progressViewStyle(.spinning)
                                    .visualEffect { content, proxy in
                                        content.scaleEffect(
                                            (buttonSize - 2 * (lineWidth * 1.2)) / proxy.size.width
                                        )
                                    }
                                    .foregroundStyle(.black)
                                    .opacity(camera.isBusyProcessing ? 1 : 0)
                                    .scaledToFill()
                            }
                            .animation(
                                .smooth(duration: 0.15),
                                value: camera.isBusyProcessing
                            )
                    }
                }
                .padding(lineWidth / 2) // stroke border would go beyond view bounds
            }
            .buttonStyle(
                .responsive(onPressingChanged: { _ in counter += 1 })
            )
            .sensoryFeedback(
                .impact(weight: .light, intensity: 0.4),
                trigger: counter
            )
            .alert(isPresented: $presentsErrorAlert, error: error) { }
        }
        
        private func takePhoto() {
            Task {
                guard camera.captureSessionState == .running else { return }
                do {
                    let capturedPhoto = try await camera.takePhoto(configuration: configuration)
                    action(capturedPhoto)
                } catch {
                    self.error = CaptureError(_error: error)
                    self.presentsErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    CameraShutterButton(
        camera: Camera(
            device: .automatic,
            profile: .photo
        )
    ) { photo in
        // Process captured photo here.
    }
    .border(.red)
}
