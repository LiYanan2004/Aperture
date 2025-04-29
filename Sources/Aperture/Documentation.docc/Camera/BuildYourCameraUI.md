# Build Your Camera UI

Build your camera UI with flexibility.

## Overview

CameraView allows you to focus on bringing great capture experience.

With built-in views and simple modifiers, you can build your camera experience with ease.

## Pre-built Camera Experience

- ``SystemCameraExperience``

System camera experience that adapts to iPhone and iPad layout, like the system Camera app.

- note: Only available on iOS.

> tip: For apps that support multiple orientation modes, you'll need to add ``AppOrientationDelegate`` to your `App` entry to make it works correctly.
>
>```swift
>import SwiftUI
>import MegaX
>
>@main
>struct MyApp: App {
>    @UIApplicationDelegateAdaptor(AppOrientationDelegate.self) var appDelegate
>    var body: some Scene { ... }
>}
>```

## Build Customized Camera Experience

When you create a camera view, you receive the camera object that represents the current camera status which you can use it to build your own controls.

For simple use cases, you can use built-in components.

### Built-in components

- ``ViewFinder``

A view that serves as camera preview.

- ``ShutterButton``

A shutter button for photo capture. 

You receive captured photo via the closure.

```swift
ShutterButton { capturedPhoto in
    let uiimage = capturedPhoto.uiimage
    // Handle image.
}
```

- ``CameraSwitcher``

A camera toggle that will toggle between front and rear camera. 

Only available on iOS.

- ``FlashLightIndicator``

An animated flashlight indicator that dynamically switches status based on current scene environment when flash mode is `.auto`.

