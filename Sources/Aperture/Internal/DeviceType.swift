//
//  DeviceType.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/29.
//

import SwiftUI

extension ProcessInfo {
    /// Queries currently running operating system type.
    package var deviceType: DeviceType {
        #if os(macOS)
        DeviceType.mac
        #elseif os(tvOS)
        DeviceType.tv
        #elseif os(visionOS)
        DeviceType.vision
        #elseif os(watchOS)
        DeviceType.watch
        #else
        DeviceType(userInterfaceIdom: UIDevice.current.userInterfaceIdiom)
        #endif
    }
}

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
    @_spi(Internal)
    public init(userInterfaceIdom: UIUserInterfaceIdiom) {
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
