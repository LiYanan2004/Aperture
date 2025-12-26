//
//  LiveBadge.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import SwiftUI

extension CameraOverlayElement {
    public struct LiveBadge: View {
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
    CameraOverlayElement.LiveBadge()
}
