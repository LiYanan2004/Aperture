# Build An Adaptive Camera Interface

Build adaptive camera UI for all platforms at once.

## Overview

Since SwiftUI does not have view modifiers to contraint allowed interface orientation, when you design your camera view using SwiftUI, you should consider make it eligible and feel natual for all interface orientation.

Aperture provides developers witg ``CameraAdaptiveStack`` to build a flexible and dynamic UI that follows the native camera layout on iPhone, iPad and Mac UI.

Here is a set of screenshots that demostrates how ``CameraAdaptiveStack`` and ``CameraAccessoryContainer`` adapts to the device context.

@TabNavigator {
    @Tab("Portrait") {  
        @Row {
            @Column(size: 1) {
                ![](iphone-portrait.png)
            }
            @Column(size: 2) {
                ![](ipad-portrait.png)
            }
        }
    }

    @Tab("Landscape Left") {
        ![](iphone-landscape-left.png)
        
        ![](ipad-landscape-left.png)
    }
    
    @Tab("Landscape Right") {
        ![](iphone-landscape-right.png)
        
        ![](ipad-landscape-right.png)
    }
}

See how ``CameraFlipButton`` is fixed to one edge of the screen in all interface orientations to provide users with a natural experience. To achieve this, use ``CameraAccessoryContainer``.

### Define your camera interface

Defines the view in portrait mode and delegate layout adjustments for other interface orientations to the adaptive stack.

```swift
CameraAdaptiveStack(camera: camera, spacing: 20) { proxy in
    CameraViewFinder(camera: camera, videoGravity: .fill)
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            ZoomButtonGroup(camera: camera)
                .contentShape(.capsule)
                .padding()
        }

    CameraAccessoryContainer(proxy: proxy, spacing: 0) {
        CameraShutterButton(
            camera: camera,
            action: saveCapturedPhoto
        ) 
    } trailingAccessories: {
        cameraSwitcher
            .padding(.vertical, 12)
    }
}
.padding()
```

### Managing custom layout

``CameraAdaptiveStackProxy`` provides you with the information on which stack it is currently using for layout:
- ``CameraAdaptiveStackProxy/primaryLayoutStack``: The layout stack used for dominant contents, for example the view finder and shutter button.
- ``CameraAdaptiveStackProxy/secondaryLayoutStack``: The layout stack used for accessory contents. This is used by ``CameraAccessoryContainer`` also.
   - If you choose to layout those accessory elements yourself, this might be useful to you as well.

To ensure the controls are always stick to one edge of the screen, the subviews' order may switch between ``CameraAdaptiveStackProxy/StackConfiguration/Order/normal`` and ``CameraAdaptiveStackProxy/StackConfiguration/Order/reversed`` based on current context. You should take it into consideration as well if your app supports multiple orientations.
