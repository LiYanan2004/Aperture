//
//  EnsureLayout.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/22.
//

import SwiftUI

nonisolated struct _AdoptsProposedSizeViewModifier: ViewModifier {
    var alignment: Alignment
    var isEnabled: Bool
    
    init(alignment: Alignment, isEnabled: Bool) {
        self.alignment = alignment
        self.isEnabled = isEnabled
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: alignment) {
            Rectangle()
                .fill(.clear)
                .layoutPriority(isEnabled ? 1 : -1)
            
            ZStack {
                content
            }
            .layoutPriority(isEnabled ? -1 : 1)
        }
    }
}

extension SwiftUI.View {
    @_spi(Internal)
    nonisolated public func adoptsProposedSize(
        alignment: Alignment = .center,
        isEnabled: Bool = true
    ) -> some View {
        modifier(_AdoptsProposedSizeViewModifier(alignment: alignment, isEnabled: isEnabled))
    }
}

#Preview {
    @Previewable @State var isEnabled = false
    
    VStack {
        Toggle("Ensures Layout", isOn: $isEnabled)
        
        Image(systemName: "photo.artframe")
            .adoptsProposedSize(isEnabled: isEnabled)
            .border(.red)
    }
    .adoptsProposedSize()
}
