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
            guard preview.session != session else { return }
            preview.session = session
        }
    }
    
    nonisolated func adjustPreview(for device: AVCaptureDevice) {
        Task { @MainActor in
            guard let connection = preview.videoPreviewLayer.connection else { return }
            #if os(iOS)
            connection.preferredVideoStabilizationMode = .previewOptimized
            #endif
            
            if connection.isVideoMirroringSupported {
                if device.position == .unspecified {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                } else {
                    connection.automaticallyAdjustsVideoMirroring = true
                }
            }
        }
    }
    
    nonisolated func setVideoGravity(_ gravity: AVLayerVideoGravity) {
        Task { @MainActor in
            layer.videoGravity = gravity
        }
    }
    
    nonisolated func freezePreview(_ freeze: Bool, animated: Bool = true) {
        #if canImport(UIKit)
        Task { @MainActor in
            if freeze {
                preview._freezePreview(animated: animated)
            } else {
                preview._unfreezePreview(animated: animated)
            }
        }
        #endif
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
    @MainActor
    class _PlatformViewBackedPreview: PlatformView {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer()

        var session: AVCaptureSession? {
            get { videoPreviewLayer.session }
            set { videoPreviewLayer.session = newValue }
        }
        
        #if os(macOS)
        override init(frame frameRect: NSRect) {
            super.init(frame: .zero)
            
            wantsLayer = true
            self.layer = CALayer()
            self.layer?.addSublayer(videoPreviewLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layout() {
            super.layout()
            videoPreviewLayer.frame = bounds
        }
        #elseif os(iOS)
        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.addSublayer(videoPreviewLayer)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            layer.addSublayer(videoPreviewLayer)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }
        #endif
        
        var _snapshotView: PlatformView?
        var snapshotLayer: CALayer? { _snapshotView?.layer }
    }
}

// MARK: - Preview Freezing

#if canImport(UIKit)
extension CameraPreview._PlatformViewBackedPreview {
    
    static let crossfadeDuration: CGFloat = 0.15
    
    func _freezePreview(animated: Bool) {
        guard _snapshotView == nil else { return }
        
        let snapshotView = self.snapshotView(afterScreenUpdates: true)
        self._snapshotView = snapshotView
        guard let snapshotView else { return }
        
        let snapshotLayer = snapshotView.layer
        self.layer.addSublayer(snapshotLayer)
        
        snapshotLayer.frame = bounds
        snapshotLayer.opacity = 1
        
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = videoPreviewLayer.presentation()?.opacity ?? videoPreviewLayer.opacity
        fadeOut.toValue = 0
        fadeOut.duration = Self.crossfadeDuration
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        CATransaction.begin()
        CATransaction.setDisableActions(animated == false)
        
        videoPreviewLayer.opacity = 0
        videoPreviewLayer.add(fadeOut, forKey: "fadeOutPreview")
        
        CATransaction.commit()
    }
    
    func _unfreezePreview(animated: Bool) {
        guard let snapshotLayer else { return }
        
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = snapshotLayer.presentation()?.opacity ?? snapshotLayer.opacity
        fadeOut.toValue = 0
        fadeOut.duration = Self.crossfadeDuration
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = videoPreviewLayer.presentation()?.opacity ?? videoPreviewLayer.opacity
        fadeIn.toValue = 1
        fadeIn.duration = Self.crossfadeDuration
        fadeIn.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        CATransaction.begin()
        CATransaction.setDisableActions(animated == false)
        CATransaction.setCompletionBlock { [weak self] in
            snapshotLayer.removeFromSuperlayer()
            self?._snapshotView = nil
        }
        
        snapshotLayer.opacity = 0
        snapshotLayer.add(fadeOut, forKey: "fadeOutOpacity")
        
        videoPreviewLayer.opacity = 1
        videoPreviewLayer.add(fadeIn, forKey: "fadeInPreview")
        
        CATransaction.commit()
    }
}
#endif
