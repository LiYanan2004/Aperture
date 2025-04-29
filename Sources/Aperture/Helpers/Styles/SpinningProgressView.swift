//
//  SpinningProgressView.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/4/29.
//

import SwiftUI

struct SpinningProgressView: ProgressViewStyle {
    @State private var isProgressing = false
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 8) {
            ProgressView()
                .hidden()
                .progressViewStyle(.circular)
                .overlay {
                    GeometryReader { proxy in
                        AngularGradient(
                            colors: [.clear, .secondary],
                            center: .center
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(.circle)
                        .mask {
                            Circle()
                                .stroke(lineWidth: min(proxy.size.height, proxy.size.width) / 5)
                        }
                        .frame(maxWidth: .infinity)
                        .rotationEffect(.degrees(isProgressing ? 360 : 0))
                    }
                }
            if let label = configuration.label {
                label
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isProgressing = true
            }
        }
    }
}

extension ProgressViewStyle where Self == SpinningProgressView {
    static var spinning: SpinningProgressView {
        SpinningProgressView()
    }
}

#Preview {
    ProgressView("Downloading")
        .progressViewStyle(.spinning)
        .controlSize(.extraLarge)
}
