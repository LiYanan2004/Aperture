# ``Camera``

An observable view model owns the camera session and reflects the camera states.

## Overview

`Camera` is an observable model that owns a capture session and exposes state used to drive your UI. Create one with a device and capture profile, then start and stop the session as your view appears.

## Topics

### Configuring a camera

- ``Camera/init(device:profile:)``
- ``Camera/device``
- ``Camera/profile``

### Managing capture session 

- ``Camera/startRunning()``
- ``Camera/stopRunning()``
- ``Camera/isAccessible``

### Managing camera state

- ``Camera/State/CaptureSessionState``
- ``Camera/State/captureSessionState``
- ``Camera/State/previewRotationAngle``
- ``Camera/State/captureRotationAngle``
- ``Camera/State/previewDimming``
- ``Camera/State/isBusyProcessing``
- ``Camera/State/shutterDisabled``
- ``Camera/State/flash``
- ``Camera/State/focusLocked``
- ``Camera/State/zoomFactor``
- ``Camera/State/displayZoomFactor``
- ``Camera/State/displayZoomFactorMultiplier``
- ``Camera/State/inProgressLivePhotoCount``

### Setting focus

- ``Camera/setManualFocus(pointOfInterest:focusMode:exposureMode:)``

### Concurrency

- ``CameraActor``
