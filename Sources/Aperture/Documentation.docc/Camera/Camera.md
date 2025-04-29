# ``Camera``

## Overview

Camera is an object with Observation. It serves as the source of truth of a single CameraView.

Access `Camera` object inside CameraView view builder, using it to start or stop the session, capture photo and more.

## Topics

### Configure Capture Session

- ``Camera/sessionState-swift.property``
- ``Camera/SessionState-swift.enum``
- ``Camera/startSession()``
- ``Camera/stopSession()``

### Capture Photo

- ``Camera/capturePhoto(completionHandler:)``
- ``CapturedPhoto``

### Shutter Status

- ``Camera/shutterDisabled``
- ``Camera/isBusyProcessing``

### Camera Position

- ``Camera/cameraSide-3lfo1``
- ``Camera/CameraSide-swift.enum``

### Focus & Flash & Zoom

- ``Camera/focusLocked``
- ``Camera/currentDeviceHasFlash-1istu``
- ``Camera/flashMode``
- ``Camera/zoomFactor``

### Orientation

- ``Camera/interfaceRotationAngle``
