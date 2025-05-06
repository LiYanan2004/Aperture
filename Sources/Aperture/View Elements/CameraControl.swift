//
//  CameraControl.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import SwiftUI

/// A view that interacting with the underlying camera manager.
///
/// - warning: Don't use this view out of the ``Camera``, which leads to a crash due to the lack of environment object.
@MainActor
@preconcurrency
public protocol CameraControl: View {
    associatedtype _Body: View
    
    /// The view representation of a camera control.
    @ViewBuilder
    func makeBody(_ context: CameraManager) -> _Body
}

extension CameraControl {
    public var body: some View {
        _CameraControl(control: self)
    }
}

private struct _CameraControl<Control: CameraControl>: View {
    @Environment(CameraManager.self) private var camera
    private var control: Control
    
    init(control: Control) {
        self.control = control
    }
    
    var body: Control._Body {
        control.makeBody(camera)
    }
}
