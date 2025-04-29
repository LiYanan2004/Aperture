# Customize Camera Experience

Customize your camera experience with view modifiers.

## Overview

With CameraView, you can use following modifiers to select camera, adjust capture pipelines and more.

### Select Appropriate Devices

By default, CameraView automatically uses virtual composed device, namely all cameras in the specific position.

- For iPhone SE, uses `.builtInWideAngleCamera` by default.
- For iPhone Xs series and iPhone Xr, uses `.builtInDualCamera` by default.
- For iPhone 11 and above, uses `.builtInDualWideCamera` by default.
- For iPhone 11 Pro series and above, uses `.builtInTrippleCamera` by default.

If you want to specify a capture device, say you want to always use wide-angle camera, you can modify the behavior via ``SwiftUICore/View/captureDeviceTypes(_:)``.

### Essential Capture Settings

- ``SwiftUICore/View/cameraStabilizationMode(_:)``
- ``SwiftUICore/View/captureQualityPrioritization(_:)``
- ``SwiftUICore/View/captureWhenMultiTaskingEnabled(_:)``

### Create More Responsive Capture Experience

For more details of these APIs, check out [Create a more responsive camera experience](https://youtu.be/nR29ju68BaI?si=l8rMsakPKqPuINML) session from WWDC 2023.

> tip: 
>
> **Decide which feature to opt-in, that's it.** 
> When you use these modifiers, you don't need to take care of the eligibility. The only thing you need to think of is whether you want to enable these features, and CameraView will try to do so if the device is capable.

**Auto Deferred Photo Delivery**

The better quality of the photo, the longer time it takes to process the photo. 

You can choose to opt-in ``SwiftUICore/View/autoDeferredPhotoDeliveryEnabled(_:)`` to let PhotoKit process the photo proxy later in background.

> You receive photo proxy inside ``ShutterButton`` action closure. For more information, check out <doc:HandleCapturedContent>.

**Zero Shutter Lag**

Reduce shutter lag by using previous frames to fuse the final photo, rather than using later frames.

Opt-in via ``SwiftUICore/View/zeroShutterLagEnabled(_:)``.

**Responsive Capture**

Enable capture pipeline to capture new photos while in processing phase, makeing shutter button available as soon as possible to capture more photos.

> important: This will raise the peak memory usage.

Opt-in via ``SwiftUICore/View/responsiveCaptureEnabled(_:fastCapturePrioritized:)``

> tip: 
>
> Zero shutter lag will be opt-in.
>
> Enable `fastCapturePrioritized` to prioritizes consistent shot-to-shot times by adapting photo quality when detects multiple, fast captures.

### Capture Consistent Color Images

For more informations, check out [Keep colors consistent across captures](https://youtu.be/YYyPZqZZtVk?si=WMK_RmiSTreSeAEi) from WWDC 2024.

Use adaptive flash to reduce color bias. 

Availability:
- iPhone 14 family and newer.
- iPad Pro (M4) and newer.

Opt-in via ``SwiftUICore/View/cameraConstantColorEnabled(_:fallbackDeliveryEnabled:)``

> important: 
> If you choose to opt-in constant color, you're forced to use `.builtInWideAngleCamera` or `.builtInDualWideCamera`.

> tip: 
>
> Be sure not to set flashMode to `.off`, otherwise, constant color will be disabled even if the device is capable.
>
> Enable `fallbackDelivery` to get original image if the confidence is lower than your expectation.
>
> To learn more about how to check the confidence map and how to get the fallback photo, check out <doc:HandleCapturedContent> and the session video.
