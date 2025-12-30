# Aperture

Integrate camera experience into your SwiftUI apps.

![](/Sources/Aperture/Documentation.docc/Resources/poster-image.png)

## Requirements

- iOS 17+
- macOS 14+

> [!IMPORTANT]
> Make sure you have added `NSCameraUsageDescription` to your app's Info.plist to access camera.

## Documentation

You can view documentation on:
- [main @ Swift Package Index](https://swiftpackageindex.com/LiYanan2004/Aperture/main/documentation/aperture/)
- [main @ GitHub Pages](https://liyanan2004.github.io/Aperture/documentation/aperture/)

## Getting Started

Add **Aperture** as a dependency in your Swift Package Manager manifest.

```swift
.package(url: "https://github.com/LiYanan2004/Aperture.git", branch: "main"),
```

Include `Aperture` in any targets that need it.

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "Aperture", package: "Aperture"),
    ]
),
```

## Usage

Create a camera, show the view finder, and place a shutter button at the bottom of the view.

```swift
import Aperture
import SwiftUI

struct CameraScreen: View {
    @State private var camera = Camera(device: .automatic, profile: .photo())

    var body: some View {
        ZStack {
            CameraViewFinder(camera: camera)
                .ignoresSafeArea()

            CameraShutterButton(camera: camera) { photo in
                // handle captured photo here.
            }
            .padding()
        }
        .task {
            try? await camera.startRunning()
        }
        .onDisappear { camera.stopRunning() }
    }
}
```

### Adaptive layout and accessories

Defines the view in portrait mode and delegate layout adjustments for other interface orientations to the adaptive stack.

```swift
CameraAdaptiveStack(camera: camera, spacing: 20) { proxy in
    CameraViewFinder(camera: camera, videoGravity: .fill)
        .ignoresSafeArea()

    CameraAccessoryContainer(proxy: proxy, spacing: 0) {
        CameraShutterButton(camera: camera) { photo in
            // handle captured photo here.
        }
    } trailingAccessories: {
        CameraFlipButton(camera: camera)
            .padding(.vertical, 12)
    }
}
```

This produces the user interface shown in the poster image.

### Configure the camera

`CameraCaptureProfile` defines the session preset and which output services are attached.

```swift
let profile = CameraCaptureProfile(sessionPreset: .photo) {
    PhotoCaptureService(options: [.zeroShutterLag, .responsiveCapture])
}
let camera = Camera(device: .automatic, profile: profile)
```

You can update output services at anytime. But keep in mind that this triggers a lengthy capture pipeline reconfiguration.

### Capture a photo

Use `PhotoCaptureConfiguration` for per-shot settings such as Live Photo and resolution.

Use of `CameraShutterButton` is highly recommended, but if you need more customization, you can call `takePhoto(configuration:)` when you needed.

```swift
let configuration = PhotoCaptureConfiguration(
    capturesLivePhoto: true
)
CameraShutterButton(camera: camera, configuration: configuration) { photo in
    // handles captured photo.
}

// or...
let photo = try await camera.takePhoto(configuration: configuration)
```

#### Apple ProRAW

Enable ProRAW on the output and opt in per shot.

```swift
let camera = Camera(device: .automatic, profile: .photo(options: .appleProRAW))

let configuration = PhotoCaptureConfiguration(
    dataFormat: .appleProRAW
)
let photo = try await camera.takePhoto(configuration: configuration)
```

Use `.appleProRAWPlusHEIF` or `.appleProRAWPlusJPEG` if you want a processed companion image.

### Custom Output Services

Implement `OutputService` when you need a custom capture output.

```swift
import AVFoundation

struct MetadataOutputService: OutputService {
    func makeOutput(context: Context) -> AVCaptureMetadataOutput {
        AVCaptureMetadataOutput()
    }

    func updateOutput(output: AVCaptureMetadataOutput, context: Context) {
        // Configure metadata output here.
    }
}

let profile = CameraCaptureProfile(sessionPreset: .photo) {
    PhotoCaptureService()
    MetadataOutputService()
}
```
