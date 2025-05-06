import SwiftUI
import AVFoundation

struct CameraPreview {
    var session: AVCaptureSession
    let preview = _PlatformViewBackedPreview()
}

#if os(macOS)
extension CameraPreview: NSViewRepresentable {
    func makeNSView(context: Context) -> _PlatformViewBackedPreview {
        preview
    }
    
    func updateNSView(_ nsView: _PlatformViewBackedPreview, context: Context) {
        DispatchQueue.main.async {
            nsView.session = session
        }
    }
}
#else
extension CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> _PlatformViewBackedPreview {
        preview
    }
    
    func updateUIView(_ nsView: _PlatformViewBackedPreview, context: Context) {
        DispatchQueue.main.async {
            nsView.session = session
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

