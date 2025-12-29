//
//  CameraAdaptiveStackProxy.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import SwiftUI

/// A proxy that describes the primary and secondary stack layouts for a camera UI.
public struct CameraAdaptiveStackProxy {
    /// A value that describes the main stack configuration used to lay out content.
    public var primaryLayoutStack: StackConfiguration
    /// A value that describes the accessory stack configuration used to lay out side content.
    public var secondaryLayoutStack: StackConfiguration
    
    internal init(interfaceRotationAngle: CGFloat) {
        switch ProcessInfo.processInfo.deviceType {
            case .pad:
                primaryLayoutStack = .init(stack: .zstack, order: .normal)
                secondaryLayoutStack = .init(stack: .vstack, order: .normal)
                
            case .phone:
                let underPortraitMode = interfaceRotationAngle.truncatingRemainder(dividingBy: 180) != 0
                let primaryOrder: StackConfiguration.Order = [0, 90].contains(interfaceRotationAngle) ? .normal : .reversed
                let secondaryOrder: StackConfiguration.Order = underPortraitMode ? primaryOrder : primaryOrder.flipped
                
                if underPortraitMode {
                    primaryLayoutStack = .init(stack: .vstack, order: primaryOrder)
                    secondaryLayoutStack = .init(stack: .hstack, order: secondaryOrder)
                } else {
                    primaryLayoutStack = .init(stack: .hstack, order: primaryOrder)
                    secondaryLayoutStack = .init(stack: .vstack, order: secondaryOrder)
                }
                
            case .macCatalyst:
                fallthrough
            case .mac:
                primaryLayoutStack = .init(stack: .vstack, order: .normal)
                secondaryLayoutStack = .init(stack: .hstack, order: .normal)
                
            default:
                preconditionFailure("\(Self.self) does not support on platform: \(ProcessInfo.processInfo.deviceType).")
        }
    }
    
    /// A value describes how to configure the stack.
    public struct StackConfiguration: Sendable {
        /// A value that selects the stack type used for layout.
        public var stack: Stack
        /// A value that controls whether children keep their order or are reversed.
        public var order: Order
        
        /// A value describes which stack to use.
        public enum Stack: Sendable {
            case vstack
            case hstack
            case zstack
        }
        
        /// A type that describes the direction used to place children in the stack.
        public enum Order: Sendable {
            case normal
            case reversed
            
            var flipped: Order {
                switch self {
                    case .normal:
                        Order.reversed
                    case .reversed:
                        Order.normal
                }
            }
        }
        
        /// Creates an instance of `AnyLayout` that matches this configuration.
        public func layout(alignment: Alignment = .center, spacing: CGFloat? = nil) -> AnyLayout {
            switch stack {
                case .vstack:
                    AnyLayout(VStackLayout(alignment: alignment.horizontal, spacing: spacing))
                case .hstack:
                    AnyLayout(HStackLayout(alignment: alignment.vertical, spacing: spacing))
                case .zstack:
                    AnyLayout(ZStackLayout(alignment: alignment))
            }
        }
    }
}

// MARK: - Stack

internal struct _CameraStack: _VariadicView_MultiViewRoot {
    internal var alignment: Alignment
    internal var spacing: CGFloat?
    internal var configuration: CameraAdaptiveStackProxy.StackConfiguration
    
    internal func body(children: _VariadicView.Children) -> some View {
        let layout = configuration.layout(alignment: alignment, spacing: spacing)
        
        let children: [_VariadicView.Children.Element] = switch configuration.order {
        case .normal:
            Array(children)
        case .reversed:
            Array(children.reversed())
        }
        
        layout {
            ForEach(children) { child in
                child
            }
        }
    }
}

