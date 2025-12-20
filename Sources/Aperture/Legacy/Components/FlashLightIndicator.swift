import SwiftUI
import AVFoundation

/// A toggle button that switches the flash mode of current capture device between on and off.
@available(watchOS, unavailable)
@available(visionOS, unavailable)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct FlashLightIndicator: View {
    private var deviceType: DeviceType {
        ProcessInfo.processInfo.deviceType
    }
    @AppStorage("Aperture_CAM_FLASH_MODE") private var userPreferedFlashMode: AVCaptureDevice.FlashMode = .auto
    
    private var accessibilityText: String {
        switch userPreferedFlashMode {
        case .off: "Flash Light off"
        case .on: "Flash Light on"
        case .auto: "Flash Light auto"
        @unknown default: "Flash light unknown"
        }
    }
    
    @State private var sceneMonitoringSetting = AVCapturePhotoSettings()
    @State private var flashSceneObserver: NSKeyValueObservation?
    @State private var isFlashScene = false
    @Namespace private var flashIndicator
    
    /// Create a flash indicator when the current capture device has flash.
    ///
    /// This view can automatically determine whether to show itself based on the current capture device capability.
    ///
    /// - note: This view must be installed inside a ``Camera``.
    public init() { }
    
    public var body: some View {
        _Legacy_CameraReader { proxy in
            if proxy.currentDeviceHasFlash {
                flashModeToggleButton(proxy._cameraManager)
            }
        }
    }
    
    private func flashModeToggleButton(_ cameraManager: CameraManager) -> some View {
        Button {
            userPreferedFlashMode = switch userPreferedFlashMode {
            case .off: .auto
            default: .off
            }
        } label: {
            Circle()
                .strokeBorder(.secondary, lineWidth: 1.25)
                .opacity(isFlashScene ? 0 : 1)
                .background {
                    Circle()
                        .foregroundStyle(.yellow)
                        .opacity(isFlashScene ? 1 : 0)
                }
                .opacity(deviceType == .phone ? 1 : 0)
                .overlay {
                    Label(accessibilityText, systemImage: "bolt.fill")
                        .foregroundStyle(isFlashScene ? .black : .white)
                        .font(.system(size: deviceType == .phone ? 16 : 20))
                }
                .mask {
                    ZStack {
                        Rectangle()
                        Capsule()
                            .frame(width: 4)
                            .padding(.vertical, -2)
                            .scaleEffect(y: userPreferedFlashMode == .off ? 1 : 0, anchor: .top)
                            .rotationEffect(.degrees(-45))
                            .blendMode(.destinationOut)
                    }
                }
                .overlay {
                    Rectangle()
                        .frame(width: 1.25)
                        .scaleEffect(y: userPreferedFlashMode == .off ? 1 : 0, anchor: .top)
                        .padding(.vertical, -2)
                        .rotationEffect(.degrees(-45))
                }
                .padding(deviceType == .pad ? 8 : 0)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: 28)
        .clipped()
        .buttonStyle(.responsive)
        .labelStyle(.iconOnly)
        .background {
            if deviceType == .pad {
                Circle()
                    .fill(isFlashScene ? AnyShapeStyle(.yellow) : AnyShapeStyle(.black.tertiary))
            }
        }
        .animation(.smooth, value: userPreferedFlashMode)
        .task(id: userPreferedFlashMode) {
            cameraManager.flashMode = CameraFlashMode(rawValue: userPreferedFlashMode) ?? .auto
            #if !os(macOS)
            sceneMonitoringSetting.flashMode = userPreferedFlashMode
            cameraManager.photoOutput.photoSettingsForSceneMonitoring = sceneMonitoringSetting
            flashSceneObserver = cameraManager.photoOutput.observe(\.isFlashScene, options: .new) { _, change in
                guard let isFlashScene = change.newValue else { return }
                Task { @MainActor in
                    withAnimation(.smooth(duration: 0.2)) {
                        self.isFlashScene = isFlashScene
                    }
                }
            }
            #endif
        }
        .onChange(of: cameraManager.flashMode) {
            userPreferedFlashMode = cameraManager.flashMode.rawValue
        }
    }
}

@available(macOS, unavailable)
#Preview {
    CameraView {
        FlashLightIndicator()
    }
}
