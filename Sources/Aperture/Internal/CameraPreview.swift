//
//  CameraPreview.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import SwiftUI
import AVFoundation

struct CameraPreview {
    let preview = _PlatformViewBackedPreview()
    
    @MainActor
    var layer: AVCaptureVideoPreviewLayer {
        preview.videoPreviewLayer
    }
    
    nonisolated func connect(to session: AVCaptureSession) {
        Task { @MainActor in
            preview.session = session
        }
    }
    
    nonisolated func adjustPreview(for device: AVCaptureDevice) {
        Task { @MainActor in
            if let connection = preview.videoPreviewLayer.connection,
               connection.isVideoMirroringSupported {
                // front camera will be mirrored by `CameraViewFinder._FlipViewModifier`
                // The position of mac built-in camera / continuity camera is `.unspecified` and we need to mirror that.
                let needsSetManually = device.position == .unspecified
                connection.automaticallyAdjustsVideoMirroring = !needsSetManually
                
                if needsSetManually {
                    connection.isVideoMirrored = true
                }
            }
        }
    }
    
    nonisolated func setVideoGravity(_ gravity: AVLayerVideoGravity) {
        Task { @MainActor in
            preview.videoPreviewLayer.videoGravity = gravity
        }
    }
}

#if os(macOS)
extension CameraPreview: NSViewRepresentable {
    func makeNSView(context: Context) -> _PlatformViewBackedPreview {
        preview
    }
    
    func updateNSView(_ view: _PlatformViewBackedPreview, context: Context) {
        
    }
}
#else
extension CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> _PlatformViewBackedPreview {
        preview
    }
    
    func updateUIView(_ view: _PlatformViewBackedPreview, context: Context) {

    }
}
#endif

// MARK: - AppKit / UIKit

extension CameraPreview {
    class _PlatformViewBackedPreview: PlatformView {
        @MainActor var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        var session: AVCaptureSession? {
            get { videoPreviewLayer.session }
            set { videoPreviewLayer.session = newValue }
        }
        
        #if os(macOS)
        init() {
            super.init(frame: .zero)
            self.layer = AVCaptureVideoPreviewLayer()
            wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        #elseif os(iOS)
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        #endif
    }
}

