# Handle Captured Content

Get captured photo in different formats.

## Overview

A ``ShutterButton`` is the essential of any capture experience, providing you with ``CapturedPhoto`` enum that contains the photo object.

### Captured Photo

Once system processed the photo, you'll get ``CapturedPhoto`` via ``ShutterButton`` action closure.

If you enabled `autoDeferredPhotoDelivery` and current photo setting is better suited to deferred photo processing, you may receive `.proxyPhoto`, otherwise, you'll receive `.photo`.

You can access these properties from ``CapturedPhoto``:

- (Optional) **UIImage / NSImage** based on your target platform.
- (Optional) **Image Data.** File representation data for captured photo. You can use it to create a `PHAssetCreationRequest`, or save the photo in your own way.
- **UnderlyingPhotoObject.** Captured photo in AVFoundation format.

For more information of how to handle `AVCaptureDeferredPhotoProxy`, check out [Create a more responsive camera experience](https://youtu.be/nR29ju68BaI?list=PLjODKV8YBFHbcwu6an3-UPkMb8bT7pD02&t=304) (timestamp attached).
