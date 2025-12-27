//
//  _FocusTargetBoundingBox.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI
import AVFoundation

@available(macOS, unavailable)
struct _FocusTargetBoundingBox: View {
    var camera: Camera
    
    enum FocusMode: Sendable, Equatable {
        case autoFocus
        case manualFocus
        /// Represents the user has released the finger after locking
        case manualFocusLocked
        /// Represents the user still touching the screen or the camera will lock focus
        case manualFocusLocking
    }
    var focusMode: FocusMode
    
    enum ExposureBiasSide: Sendable, Equatable {
        case left, right
        var alignment: Alignment {
            switch self {
            case .left: .leading
            case .right: .trailing
            }
        }
    }
    @State private var exposureBiasSide = ExposureBiasSide.right
    @State private var isUnlocked = false
    @State private var exposureY = CGFloat.zero
    @State private var lastExposureY = CGFloat.zero
    
    @State private var currentPhase: FocusPhase?
    private var opacity: Double { (currentPhase ?? .invisibleLarge).opacity }
    private var scale: CGFloat { (currentPhase ?? .invisibleLarge).scale }
    
    @State private var focusTrackingTask: Task<Void, Error>?
    @State private var idleTimer: Task<Void, Error>?
    
    var body: some View {
        focusedAreaIndicator
            .overlay(alignment: exposureBiasSide.alignment) {
                if focusMode != .autoFocus {
                    exposureSlider
                }
            }
            .environment(\.colorScheme, .dark)
            .opacity(opacity)
            .scaleEffect(scale)
            .overlay {
                GeometryReader { proxy in
                    Color.black
                        .padding(-32)
                        .opacity(0.001)
                        .onAppear {
                            let previewWidth = proxy.bounds(of: .named("PREVIEW"))!.size.width
                            let trailingEdgeX = proxy.frame(in: .named("PREVIEW")).maxX
                            if trailingEdgeX + 36 > previewWidth {
                                self.exposureBiasSide = .left
                            }
                        }
                }
                .gesture(exposureAdjustmentGesture)
            }
            .onAppear(perform: scheduleAnimation)
            .onDisappear { focusTrackingTask?.cancel() }
            .onChange(of: focusMode) {
                focusTrackingTask?.cancel()
                withAnimation(.smooth(duration: 0.25)) {
                    currentPhase = .normal
                }
            }
            .environment(\.layoutDirection, .leftToRight)
    }
    
    private var focusedAreaIndicator: some View {
        Rectangle()
            .stroke(.yellow, lineWidth: 1)
            .overlay {
                Rectangle()
                    .fill(.yellow)
                    .frame(width: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask {
                        VStack {
                            Color.black.frame(height: 5)
                            Spacer()
                            Color.black.frame(height: 5)
                        }
                    }
            }
            .overlay {
                Rectangle()
                    .fill(.yellow)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask {
                        HStack {
                            Color.black.frame(width: 5)
                            Spacer()
                            Color.black.frame(width: 5)
                        }
                    }
            }
            .aspectRatio(1, contentMode: .fit)
    }
    
    private var exposureSlider: some View {
        Canvas { context, size in
            context.translateBy(x: size.width / 2, y: 0)
            
            if exposureY != .zero {
                let sliderRect = CGRect(origin: .zero, size: CGSize(width: 1, height: size.height))
                context.fill(Rectangle().path(in: sliderRect), with: .color(.yellow))
            }
            
            context.blendMode = .clear
            
            let sunOrigin = CGPoint(x: -16, y: size.height / 2 - 16 + exposureY)
            let sunSize = CGSize(width: 32, height: 32)
            let sunRect = CGRect(origin: sunOrigin, size: sunSize)
            context.fill(Circle().path(in: sunRect), with: .color(.black))
            if let sun = context.resolveSymbol(id: "sun") {
                context.draw(sun, at: CGPoint(x: 0, y: size.height / 2 + exposureY))
            }
        } symbols: {
            Image(systemName: "sun.max.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .fontWeight(.thin)
                .tag("sun")
        }
        .frame(width: 24)
        .padding(.vertical, -16)
        .offset(x: exposureBiasSide == .right ? 32 : -32)
        .foregroundStyle(.yellow)
    }
    
    private func scheduleAnimation() {
        switch focusMode {
        case .autoFocus, .manualFocus:
            withAnimation(.snappy(duration: 0.35)) {
                currentPhase = .normal
            } completion: {
                withAnimation(.easeInOut(duration: 0.2).repeatForever()) {
                    currentPhase = .dimmed
                }
            }
        case .manualFocusLocking:
            currentPhase = .invisibleLarge
            withAnimation(.linear(duration: 0.2).repeatCount(2)) {
                currentPhase = .visibleLarge
            } completion: {
                guard self.currentPhase != .normal else { return }
                currentPhase = .visibleExtraLarge
                withAnimation(.linear(duration: 0.2).repeatCount(2, autoreverses: false)) {
                    currentPhase = .visibleLarge
                }
            }
        case .manualFocusLocked: break
        }
        
        #if !targetEnvironment(simulator)
        focusTrackingTask = Task.detached(operation: trackFocusState)
        #endif
    }
    
    private var exposureAdjustmentGesture: some Gesture {
        DragGesture()
            .map { $0.translation.height * 0.1 }
            .onChanged {
                idleTimer?.cancel()
                currentPhase = .normal
                do {
                    guard let device = camera.device.captureDevice else { return }
                    if !isUnlocked {
                        try device.lockForConfiguration()
                        self.isUnlocked = true
                    }
                    self.exposureY = max(-37.5, min(37.5, self.lastExposureY + $0))
                    let ev = -self.exposureY / 37.5 * 3.0
                    device.exposureMode = .autoExpose
                    device.setExposureTargetBias(Float(ev))
                } catch {
                    camera.coordinator.logger.error("Cannot lock device for configuration: \(error.localizedDescription)")
                }
            }
            .onEnded { _ in
                updateFocusIndicator()
                camera.device.captureDevice?.unlockForConfiguration()
                self.isUnlocked = false
                self.lastExposureY = self.exposureY
            }
    }
    
    @Sendable private func trackFocusState() async {
        defer { updateFocusIndicator() }
        
        guard let device = camera.device.captureDevice else { return }
        
        var lensPosition = device.lensPosition
        let timeout = 1000 // Timeout for stopping finding a focus if we cannot
        var waitingTime = 0 // Time(ms) elapse since now based on `Task.sleep`
       
        // Determine whether the camera is now focusing
        while device.lensPosition == lensPosition {
            guard !Task.isCancelled else { return }
            guard waitingTime <= timeout else { return }
            // If current lensPosition equals to the previous one,
            // it means camera is not start focusing.
            // Wait a short period of time.
            try? await Task.sleep(for: .milliseconds(10))
            waitingTime += 10
        }
        
        let threshold = 10 // The threshold to determine whether the focus has been adjusted
        var count = 0 // Count for same value.
        lensPosition = device.lensPosition
            
        // Determine whether the camera has finished focusing
        while count <= threshold {
            guard !Task.isCancelled else { return }
            if device.lensPosition == lensPosition {
                count += 1
            } else {
                lensPosition = device.lensPosition
                count = 0
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
    
    private func updateFocusIndicator() {
        guard !Task.isCancelled else { return }
        guard focusMode == .manualFocus else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPhase = .normal
        } completion: {
            guard focusMode == .manualFocus else { return }
            idleTimer = Task {
                try? await Task.sleep(for: .seconds(2))
                try Task.checkCancellation()
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentPhase = .idle
                }
            }
        }
    }
}

@available(macOS, unavailable)
extension _FocusTargetBoundingBox {
    struct FocusPhase: Equatable {
        var opacity: Double
        var scale: CGFloat
        
        static let visibleExtraLarge = FocusPhase(opacity: 1, scale: 2)
        static let visibleLarge = FocusPhase(opacity: 1, scale: 1.5)
        static let dimmedLarge = FocusPhase(opacity: 0.5, scale: 1.5)
        static let invisibleLarge = FocusPhase(opacity: 0, scale: 1.5)
        static let normal = FocusPhase(opacity: 1, scale: 1)
        static let dimmed = FocusPhase(opacity: 0.5, scale: 1)
        static let idle = FocusPhase(opacity: 0.3, scale: 1)
    }
}

#if os(iOS)
#Preview {
    _FocusTargetBoundingBox(
        camera: Camera(device: .builtInCamera(), profile: .photo),
        focusMode: .manualFocusLocking
    )
    .frame(width: 100, height: 100)
    .preferredColorScheme(.dark)
    .coordinateSpace(.named("PREVIEW"))
}
#endif
