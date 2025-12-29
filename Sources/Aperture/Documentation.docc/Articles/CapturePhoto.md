# Capture Photo

Captures still images or Live Photos.

## Overview

Capture photos by adding ``PhotoCaptureService`` to a ``CameraCaptureProfile``

Use ``PhotoCaptureOptions`` for pipeline-wide behavior and ``PhotoCaptureConfiguration`` for per-shot settings.

### Configuring a capture profile

Add a photo capture service to the profile you pass into ``Camera``:

```swift
let profile = CameraCaptureProfile(sessionPreset: .photo) {
    PhotoCaptureService(options: [.zeroShutterLag, .responsiveCapture])
}
let camera = Camera(device: .automatic, profile: profile)
```

### Requesting photo pipeline features

Set options on ``PhotoCaptureService`` to opt into advanced capture behaviors:

- ``PhotoCaptureOptions/zeroShutterLag`` to reduce shutter lag by using buffered frames.
- ``PhotoCaptureOptions/responsiveCapture`` to overlap capture and processing for faster shot-to-shot time (requires zero shutter lag).
- ``PhotoCaptureOptions/fastCapturePrioritization`` to keep shot-to-shot speed steady during bursts (requires responsive capture).
- ``PhotoCaptureOptions/autoDeferredPhotoDelivery`` to allow proxy delivery for later processing and reducing shot-to-shot latency.
- ``PhotoCaptureOptions/constantColor`` to reduce ambient color bias to represents the correct color, such as skin colors, and more.

For more information on availability and constraints, see ``PhotoCaptureOptions``.

### Configuring per-shot settings

Use ``PhotoCaptureConfiguration`` to set per-shot capture preferences:

```swift
let configuration = PhotoCaptureConfiguration(
    capturesLivePhoto: true,
    resolution: .`12mp`,
    dataFormat: .heif,
    qualityPrioritization: .balanced
)
```

For capturing 24MP photos, opt-in ``PhotoCaptureOptions/autoDeferredPhotoDelivery`` and set ``PhotoCaptureConfiguration/qualityPrioritization`` to `.quality`.

> tip:
> You can use the convenience method ``PhotoCaptureConfiguration/configuredFor24MPPhotoCapture()`` to setup the configuration

### Capturing a photo

You should use ``CameraShutterButton`` in the first place.

If you want to use your custom controls, call ``Camera/takePhoto(configuration:)`` to trigger a capture and receive a ``CapturedPhoto`` value:

```swift
let capturedPhoto = try await camera.takePhoto(configuration: configuration)
```

### Handling captured data

``CapturedPhoto`` contains the primary image data, optional Live Photo resources, and more.

- ``CapturedPhoto/data`` is the primary image data.
- ``CapturedPhoto/isProxy`` indicates deferred proxy delivery; save proxy data with PhotoKit when present.
- ``CapturedPhoto/livePhotoMovieURL`` contains the Live Photo movie URL when available.
- ``CapturedPhoto/constantColorFallbackPhotoData`` provides a fallback image when constant color output is not fully processed.
