# Capturing and saving still and Live Photos

Learn how to configure the pipeline to capture still and Live Photos.

## Overview

Capture photos by adding ``PhotoCaptureService`` to a ``CameraCaptureProfile``

Use ``PhotoCaptureOptions`` for pipeline-wide behavior and ``PhotoCaptureConfiguration`` for per-shot settings.

### Configuring a capture profile

Add a photo capture service to the profile you pass into ``Camera``:

```swift
let profile = CameraCaptureProfile(sessionPreset: .photo) {
    PhotoCaptureService(options: [.zeroShutterLag, .responsiveCapture])
}
let camera = Camera(device: .builtInCamera, profile: profile)
```

### Requesting photo pipeline features

Set options on ``PhotoCaptureService`` to opt into advanced capture behaviors:

- ``PhotoCaptureOptions/zeroShutterLag`` to reduce shutter lag by using buffered frames.
- ``PhotoCaptureOptions/responsiveCapture`` to overlap capture and processing for faster shot-to-shot time (requires zero shutter lag).
- ``PhotoCaptureOptions/fastCapturePrioritization`` to keep shot-to-shot speed steady during bursts (requires responsive capture).
- ``PhotoCaptureOptions/autoDeferredPhotoDelivery`` to allow proxy delivery for later processing and reducing shot-to-shot latency.
- ``PhotoCaptureOptions/deliversDepthData`` to request depth data and portrait effects matte delivery when supported.
- ``PhotoCaptureOptions/constantColor`` to reduce ambient color bias to represent the correct color, such as skin colors, and more.
- ``PhotoCaptureOptions/appleProRAW`` to enable Apple ProRAW capture on supported devices.

For more information on availability and constraints, see ``PhotoCaptureOptions``.

### Configuring per-shot settings

Use ``PhotoCaptureConfiguration`` to set per-shot capture preferences:

```swift
let configuration = PhotoCaptureConfiguration()
```

You can configure the preferred resolution, Live Photo, and more.

##### 24MP Photos

For capturing 24MP photos, opt-in ``PhotoCaptureOptions/autoDeferredPhotoDelivery`` and set ``PhotoCaptureConfiguration/qualityPrioritization`` to `.quality`.

> tip:
> You can use the convenience method ``PhotoCaptureConfiguration/configuredFor24MPPhotoCapture()`` to setup the configuration

##### RAW Photo

To request RAW delivery, set ``PhotoCaptureConfiguration/dataFormat`` to `.raw` for RAW-only delivery, or `.rawPlusHEIF` / `.rawPlusJPEG` to include a processed companion image.

Availability depends on the device and active camera:
- Apple ProRAW is supported on iPhone 12 Pro / Pro Max and later Pro models.
- Bayer RAW is available on supported iPhone and iPad devices only when using a single camera (e.g. wide angle camera, ultra-wide camera, etc.).

By default, it captures Bayer RAW unless you opt-in ``PhotoCaptureOptions/appleProRAW`` on the output.

```swift
let profile = CameraCaptureProfile(sessionPreset: .photo) {
    PhotoCaptureService(options: .appleProRAW)
}
let configuration = PhotoCaptureConfiguration(dataFormat: .raw)
```

### Capturing a photo

You should use ``CameraShutterButton`` in the first place.

You can also capture a photo programmatically via ``Camera/takePhoto(configuration:dataRepresentationCustomizer:)`` and receive a ``CapturedPhoto`` value:

```swift
let capturedPhoto = try await camera.takePhoto(configuration: configuration)
```

### Handling captured data

``CapturedPhoto`` can include multiple data representations from a single shutter press, such as a processed image, a photo proxy, an Apple ProRAW DNG, or a constant color fallback photo.

Retrieve the data based on your needs via ``CapturedPhoto/data(for:)``.

For photo proxy, you should save it via `PhotoKit` as soon as possible when you get that to allow post-processing. Especially when you requested a `24MP` photo capture.

```swift
try await PHPhotoLibrary.shared().performChanges {
    PHAssetCreationRequest.forAsset().addResource(with: .photoProxy, data: data, options: nil)
}
```

If you save Apple ProRAW with a processed companion image to the photo library, follow these rules:
- Processed image data should be the primary data
- Apple ProRAW data should be the alternative photo and saved via `addResource(with:fileURL:options:)`

This example saves the processed image and Apple ProRAW data to the photo library:

```swift
import Photos

try await PHPhotoLibrary.shared().performChanges {
    let creationRequest = PHAssetCreationRequest.forAsset()
    if let data = capturedPhoto.data(for: .processed) {
        creationRequest.addResource(
            with: .photo,
            data: data,
            options: nil
        )
    }

    if let data = capturedPhoto.data(for: .appleProRAW) {
        let uniqueURLForDNGFile = URL
            .temporaryDirectory
            .appending(path: "Captured ProRAW photo at \(Date.now.formatted(.iso8601)).DNG")
        try? data.write(to: uniqueURLForDNGFile)
        
        let options = PHAssetResourceCreationOptions()
        options.shouldMoveFile = true
        creationRequest.addResource(
            with: .alternatePhoto,
            fileURL: uniqueURLForDNGFile,
            options: options
        )
    }
}
```
