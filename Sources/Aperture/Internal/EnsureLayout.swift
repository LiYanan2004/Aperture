//
//  EnsureLayout.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/22.
//

import SwiftUI

nonisolated struct _EnsureLayoutViewModifier: ViewModifier {
    var alignment: Alignment
    
    init(alignment: Alignment) {
        self.alignment = alignment
    }
    
    func body(content: Content) -> some View {
        Rectangle()
            .fill(.clear)
            .overlay(alignment: alignment) { content }
    }
}

extension SwiftUI.View {
    @_spi(Internal)
    nonisolated public func ensureLayout(alignment: Alignment = .center) -> some View {
        modifier(_EnsureLayoutViewModifier(alignment: alignment))
    }
}
