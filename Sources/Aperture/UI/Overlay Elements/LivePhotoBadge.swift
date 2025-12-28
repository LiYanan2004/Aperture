//
//  LivePhotoBadge.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import SwiftUI

extension CameraOverlayElement {
    /// The Live Photo badge which is used to indicating live photo capture state.
    public struct LivePhotoBadge: View {
        /// Creates a live photo badge
        public init() { }
        
        public var body: some View {
            Text("LIVE")
                .foregroundStyle(.black.opacity(0.5))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background {
                    Color.yellow
                        .compositingGroup()
                        .overlay {
                            Text("LIVE")
                                .foregroundStyle(.black)
                                .blendMode(.destinationOut)
                        }
                        .drawingGroup()
                }
                .font(.subheadline)
                .kerning(1)
                .clipShape(.rect(cornerRadius: 6))
        }
    }
}

#Preview {
    CameraOverlayElement.LivePhotoBadge()
}
