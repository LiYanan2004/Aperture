//
//  DeviceType.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/29.
//

import SwiftUI

/// Device type enum that represent the device users are currently using.
package enum DeviceType: Int, @unchecked Sendable {
    /// Devices running iOS, typically iPhone and iPod.
    case phone
    /// Devices running iPadOS.
    case pad
    /// Devices running tvOS.
    case tv
    /// Devices running watchOS.
    case watch
    /// Devices running macOS and fully native macOS experience.
    case mac
    /// Devices running macOS but the app experience is powered by Mac Catalyst.
    case macCatalyst
    /// Devices running visionOS.
    case vision
    /// Devices in CarPlay experience.
    case carPlay
    /// Unknown type of current device.
    case unspecified
    
    #if os(iOS) || os(tvOS) || os(visionOS)
    internal init(userInterfaceIdom: UIUserInterfaceIdiom) {
        switch userInterfaceIdom {
        case .unspecified: self = .unspecified
        case .phone: self = .phone
        case .pad: self = .pad
        case .tv: self = .tv
        case .carPlay: self = .carPlay
        case .mac: self = .macCatalyst
        case .vision: self = .vision
        @unknown default: self = .unspecified
        }
    }
    #endif
}

/// Environment key for accessing device type.
struct DeviceTypeEnvironmentKey: EnvironmentKey {
    #if os(macOS)
    static let defaultValue: DeviceType = .mac
    #elseif os(tvOS)
    static let defaultValue: DeviceType = .tv
    #elseif os(visionOS)
    static let defaultValue: DeviceType = .vision
    #elseif os(watchOS)
    static let defaultValue: DeviceType = .watch
    #else
    static let defaultValue: DeviceType = DeviceType(userInterfaceIdom: UIDevice.current.userInterfaceIdiom)
    #endif
}

extension EnvironmentValues {
    /// The type of current device.
    ///
    /// You get this value through `@Environment(\.deviceType) var deviceType`.
    ///
    /// The value of this property is get-only.
    ///
    /// The app natively to the macOS or using Catalyst typically using different layout strategy,
    /// so `DeviceType.mac` and `DeviceType.macCatalyst` are two different targets.
    package var deviceType: DeviceType {
        get { self[DeviceTypeEnvironmentKey.self] }
    }
}
