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
        var session: CameraSession
        private var camera: (any Camera)? {
            session.camera
        }
        
        @State private var initialFactor: CGFloat?
        
        private var minZoomFactor: CGFloat {
            #if os(iOS)
            camera?.device?.minAvailableVideoZoomFactor ?? 1
            #else
            1
            #endif
        }
        private var maxZoomFactor: CGFloat {
            #if os(iOS)
            5.0 * CGFloat(truncating: camera?.device?.virtualDeviceSwitchOverVideoZoomFactors.last ?? 1)
            #else
            1
            #endif
        }
        
        public var body: some Gesture {
            MagnifyGesture()
                #if os(iOS)
                .onChanged { value in
                    guard let camera, let cameraDevice = camera.device else { return }
                    
                    if initialFactor == nil {
                        do {
                            try cameraDevice.lockForConfiguration()
                            self.initialFactor = session.zoomFactor
                        } catch {
                            session.logger.error("Zoom gesture failed: \(error.localizedDescription)")
                        }
                    }
                    guard let initialFactor else { return }
                    
                    switch camera.position {
                        case .front:
                            // Toggle between 12MP and 8MP for front camera
                            session.zoomFactor = value.magnification > 1 ? 1.3 : 1
                        case .back:
                            let zoomFactor = min(max(minZoomFactor, initialFactor * (value.magnification)), maxZoomFactor)
                            session.zoomFactor = zoomFactor
                    }
                }
                .onEnded { _ in
                    camera?.device?.unlockForConfiguration()
                    initialFactor = nil
                }
                #endif
        }
    }
}
