//
//  PlatformView.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/29.
//

import SwiftUI

#if os(macOS)
package typealias PlatformView = NSView
#elseif os(iOS)
package typealias PlatformView = UIView
#endif
