# ``PhotoCaptureOptions``

Use `PhotoCaptureOptions` with ``PhotoCaptureService`` to enable pipeline-wide behaviors like zero shutter lag, responsive capture, deferred delivery, depth data delivery, constant color, or Apple ProRAW.

Options are requests: the system may ignore them based on device capabilities, the active format, per-shot settings, or runtime conditions. For per-shot choices such as RAW delivery or resolution, use ``PhotoCaptureConfiguration``.

## Topics

### Getting pipeline options

- ``PhotoCaptureOptions/zeroShutterLag``
- ``PhotoCaptureOptions/responsiveCapture``
- ``PhotoCaptureOptions/fastCapturePrioritization``
- ``PhotoCaptureOptions/autoDeferredPhotoDelivery``
- ``PhotoCaptureOptions/deliversDepthData``
- ``PhotoCaptureOptions/constantColor``
- ``PhotoCaptureOptions/appleProRAW``

### Accessing option presets

- ``PhotoCaptureOptions/default``
- ``PhotoCaptureOptions/prioritizingShotToShotLatency``
- ``PhotoCaptureOptions/captures24MPPhotos``
