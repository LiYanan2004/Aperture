# Connect output service

Connect any output service to camera pipeline in order to receive data output.

## Overview

Output services are the capture outputs that plug into the camera session. Each service creates an `AVCaptureOutput` (such as a photo output) and configures it using the current session and device input, so you can decide what data the camera produces.

### Attaching output service to the camera

Declare one or more output services in a ``CameraCaptureProfile`` and pass the profile into ``Camera``. The services are created and attached when the capture session is configured.

```swift
let profile = CameraCaptureProfile(sessionPreset: .photo) {
    PhotoCaptureService(options: .default.union(.responsiveCapture))
}
let camera = Camera(device: .automatic, profile: profile)
```

### Updating output services

At any time, you can re-configure the active output services attached to the camera object.

You do that by updating the capture profile:

```swift
camera.profile.outputServices = [PhotoCaptureService(options: newOptions)]
```

But notice that changing this property requires a lengthy reconfiguration of the capture render pipeline under the hood.

### Custom Output Services

Implement ``OutputService`` when you need to customize the output.

You declare a custom output service just like how you bridge UIKit / AppKit view into SwiftUI.

```swift
import AVFoundation

struct MetadataOutputService: OutputService {
    func makeCoordinator() -> Coordinator {
        /* initializer your coordinator */
    }

    func makeOutput(context: Context) -> AVCaptureMetadataOutput {
        AVCaptureMetadataOutput()
    }

    func updateOutput(output: AVCaptureMetadataOutput, context: Context) {
        // Configure metadata output here.
    }

    final class Coordinator: NSObject/*, xxxDelegate */ {
        
    }
}

let profile = CameraCaptureProfile(sessionPreset: .photo) {
    PhotoCaptureService()
    MetadataOutputService()
}
let camera = Camera(device: .automatic, profile: profile)
```
