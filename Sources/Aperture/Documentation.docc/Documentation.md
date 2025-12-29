# ``Aperture``

Integrate camera experience into your SwiftUI apps.

## Overview

Aperture offers an easy and flexible way for SwiftUI developers to integrate the camera experience into their apps, with support for advanced capture pipelines like zero shutter lag, responsive capture, and constant color. The framework keeps camera state observable so your UI can stay in sync with capture activity.

From a user-interface perspective, since SwiftUI does not support locking interface orientation, Aperture provides dynamic camera UI and adaptive layout helpers to keep the experience consistent across orientations and devices.

![](poster-image.png)

## Topics

### Essentials

- ``Camera``
- ``CameraCaptureProfile``

### Integrating camera interface

- <doc:CameraUI>
- <doc:AdaptiveCameraUI>
- ``CameraAdaptiveStackProxy``
- ``CameraAdaptiveStack``
- ``CameraAccessoryContainer``

### Choosing a camera

- <doc:CameraDevice>
- <doc:BuiltInCamera>
- ``ExternalCamera``

### Connecting outputs

- <doc:ConnectOutputService>
- ``OutputService``
- ``OutputServiceContext``
- ``OutputServiceBuilder``

### Capturing photos

- <doc:CapturePhoto>
- ``PhotoCaptureService``
- ``PhotoCaptureOptions``
- ``PhotoCaptureConfiguration``
- ``CapturedPhoto``
