//
//  CameraViewFinder.zoom.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI
import AVFoundation

extension CameraViewFinder {
    struct _ZoomGesture: Gesture {
        var camera: Camera
        private var device: (any CameraDevice)? {
            camera.device
        }
        
        @State private var initialFactor: CGFloat?
        
        private var minZoomFactor: CGFloat {
            #if os(iOS)
            device?.captureDevice?.minAvailableVideoZoomFactor ?? 1
            #else
            1
            #endif
        }
        private var maxZoomFactor: CGFloat {
            #if os(iOS)
            5.0 * CGFloat(truncating: device?.captureDevice?.virtualDeviceSwitchOverVideoZoomFactors.last ?? 1)
            #else
            1
            #endif
        }
        
        public var body: some Gesture {
            MagnifyGesture()
                #if os(iOS)
                .onChanged { value in
                    guard let captureDevice = device?.captureDevice else { return }
                    
                    if initialFactor == nil {
                        do {
                            try captureDevice.lockForConfiguration()
                            self.initialFactor = camera.zoomFactor
                        } catch {
                            camera.coordinator.logger.error("Zoom gesture failed: \(error.localizedDescription)")
                        }
                    }
                    guard let initialFactor else { return }
                    
                    if captureDevice.position == .front {
                        // Toggle between 12MP and 8MP for front device
                        camera.zoomFactor = value.magnification > 1 ? 1.3 : 1
                    } else {
                        let zoomFactor = min(max(minZoomFactor, initialFactor * (value.magnification)), maxZoomFactor)
                        camera.zoomFactor = zoomFactor
                    }
                }
                .onEnded { _ in
                    device?.captureDevice?.unlockForConfiguration()
                    initialFactor = nil
                }
                #endif
        }
    }
}
