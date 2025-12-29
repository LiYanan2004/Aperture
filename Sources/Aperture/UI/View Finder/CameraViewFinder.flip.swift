//
//  CameraViewFinder.flip.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import SwiftUI
import AVFoundation

extension CameraViewFinder {
    struct _FlipViewModifier: ViewModifier {
        var trigger: CameraPosition
        @State private var scale: Scale = .normal
        @State private var rotationAngle: CGFloat = .zero
        
        enum Scale: CGFloat {
            case smaller = 0.9
            case normal = 1.0
        }
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(scale.rawValue)
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0.0, y: 1.0, z: 0.0),
                    perspective: 0
                )
                .onChange(of: trigger) {
                    rotationAngle = switch trigger {
                        case .back: -180
                        case .front: 180
                    }
                    withAnimation(.smooth(duration: 0.4)) {
                        rotationAngle = .zero
                    }
                    
                    withAnimation(.smooth(duration: 0.2)) {
                        scale = .smaller
                    } completion: {
                        withAnimation(.smooth(duration: 0.2)) {
                            scale = .normal
                        }
                    }
                }
        }
    }
    
    fileprivate struct _FlipSide: Equatable {
        var rotation3DAngle: Double
        var scale: CGFloat
        
        static var front = _FlipSide(rotation3DAngle: 0, scale: 1)
        static var back = _FlipSide(rotation3DAngle: -180, scale: 1)
    }
}
