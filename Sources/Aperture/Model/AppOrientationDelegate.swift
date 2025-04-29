import SwiftUI

#if os(iOS)
/// An AppDelegate specifically focused on orientation management for application.
///
/// If you have implemented your own `AppDelegate`, you can inherit from ``AppOrientationDelegate``, and be sure not to override the implementations of ``AppOrientationDelegate``
public class AppOrientationDelegate: NSObject, UIApplicationDelegate {
    static var defaultOrientation = UIInterfaceOrientationMask.allButUpsideDown
    static var orientationLock = UIInterfaceOrientationMask.allButUpsideDown
    
    public func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppOrientationDelegate.orientationLock
    }
}

// MARK: - Orientation Lock Preferences

struct DefaultOrientationMask: PreferenceKey {
    static var defaultValue: UIInterfaceOrientationMask { UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown }
    
    static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) {
        value = nextValue()
    }
}

struct DeviceOrientationMask: PreferenceKey {
    static var defaultValue: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
    }
    
    static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) {
        value = nextValue()
    }
}

// MARK: - View + Orientation Lock

extension View {
    private func updateOrientation(_ orientation: UIInterfaceOrientationMask) {
        UIInterfaceOrientation.updateOrientation(orientation)
    }
    
    func deviceOrientation(_ orientation: UIInterfaceOrientationMask) -> some View {
        preference(
            key: DeviceOrientationMask.self,
            value: orientation
        )
        .onPreferenceChange(DeviceOrientationMask.self, perform: updateOrientation(_:))
        .onAppear {
            updateOrientation(orientation)
        }
        .onDisappear {
            updateOrientation(AppOrientationDelegate.defaultOrientation)
        }
    }
    
    func defaultOrientationMask(_ orientation: UIInterfaceOrientationMask) -> some View {
        preference(
            key: DefaultOrientationMask.self,
            value: orientation
        )
        .onPreferenceChange(DefaultOrientationMask.self) {
            AppOrientationDelegate.defaultOrientation = $0
            /// `defaultOrientation` == `orientationLock` means
            /// there is no other orientation lockers been activated. In this case,
            /// if the default orientation changes, we need to update current orientation.
            guard AppOrientationDelegate.defaultOrientation == AppOrientationDelegate.orientationLock else { return }
            updateOrientation($0)
        }
        .onAppear {
            updateOrientation(orientation)
        }
    }
}

// MARK: - UIInterfaceOrientation + Update

extension UIInterfaceOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        let orientation: UIInterfaceOrientation = {
            switch deviceOrientation {
            case .portraitUpsideDown: UIInterfaceOrientation.portraitUpsideDown
            case .landscapeLeft: UIInterfaceOrientation.landscapeLeft
            case .landscapeRight: UIInterfaceOrientation.landscapeRight
            default: UIInterfaceOrientation.portrait
            }
        }()
        self.init(rawValue: orientation.rawValue)
    }
    
    static func updateOrientation(_ orientation: UIInterfaceOrientationMask) {
        AppOrientationDelegate.orientationLock = orientation
        // Tells System to re-call
        // `application(_:supportedInterfaceOrientationsFor)` method
        if #available(iOS 16.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            // Manually rotate your screen and refresh InterfaceMask.
            let newOrientation: UIInterfaceOrientation = {
                switch orientation {
                case .portrait: return .portrait
                case .landscapeLeft: return .landscapeLeft
                case .landscapeRight: return .landscapeRight
                case .portraitUpsideDown: return .portraitUpsideDown
                default:
                    let current = UIInterfaceOrientation(deviceOrientation: UIDevice.current.orientation)!
                    guard orientation != .all else { return current }
                    if orientation == .allButUpsideDown  {
                        return current == .portraitUpsideDown ? .portrait : current
                    }
                    if current != .landscapeLeft && current != .landscapeRight {
                        return .landscapeLeft
                    } else {
                        return current
                    }
                }
            }()
            UIDevice.current.setValue(newOrientation.rawValue, forKey: "orientation")
            // Always send a notification in case the device orientation doesn't change
            NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
}
#endif
