//
//  CameraAdaptiveStackProxy.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import SwiftUI

public struct CameraAdaptiveStackProxy {
    public var primaryLayoutStack: StackConfiguration
    public var secondaryLayoutStack: StackConfiguration
    
    init(interfaceRotationAngle: CGFloat) {
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
    
    public struct StackConfiguration: Sendable {
        public var stack: Stack
        public var order: Order
        
        public enum Stack: Sendable {
            case vstack
            case hstack
            case zstack
        }
        
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
        
        public func layout(spacing: CGFloat? = nil) -> AnyLayout {
            switch stack {
            case .vstack:
                AnyLayout(VStackLayout(spacing: spacing))
            case .hstack:
                AnyLayout(HStackLayout(spacing: spacing))
            case .zstack:
                AnyLayout(ZStackLayout())
            }
        }
    }
}

// MARK: - Stack

internal struct _CameraStack: _VariadicView_MultiViewRoot {
    internal var spacing: CGFloat?
    internal var configuration: CameraAdaptiveStackProxy.StackConfiguration
    
    internal func body(children: _VariadicView.Children) -> some View {
        let layout = configuration.layout(spacing: spacing)
        
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

