//
//  CameraPreview.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import SwiftUI
import AVFoundation

@MainActor struct CameraPreview {
    var session: AVCaptureSession
    let preview = _PlatformViewBackedPreview()
}

#if os(macOS)
extension CameraPreview: NSViewRepresentable {
    func makeNSView(context: Context) -> _PlatformViewBackedPreview {
        preview
    }
    
    func updateNSView(_ view: _PlatformViewBackedPreview, context: Context) {
        DispatchQueue.main.async {
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            view.session = session
        }
    }
}
#else
extension CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> _PlatformViewBackedPreview {
        preview
    }
    
    func updateUIView(_ view: _PlatformViewBackedPreview, context: Context) {
        DispatchQueue.main.async {
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            view.session = session
        }
    }
}
#endif

// MARK: - AppKit / UIKit

extension CameraPreview {
    class _PlatformViewBackedPreview: PlatformView {
        package var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
            }
            return layer
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

