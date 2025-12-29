//
//  ViewAspectRatioHelper.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/10.
//

import SwiftUI

extension View {
    @_spi(Internal)
    nonisolated public func fitAspectRatio(_ aspectRatio: CGFloat, ignoreSafeAreaEdges: Edge.Set = []) -> some View {
        modifier(_FitAspectRatioViewModifier(aspectRatio, ignoreSafeAreaEdges: ignoreSafeAreaEdges))
    }
}

/// A view modifier that adds extra spaces to a view to follow the aspect ratio, respecting safe areas if there's, to create view with correct aspect ratio.
///
/// When you want to set the aspect ratio for a view, you may use this pattern:
///
/// ```swift
/// Rectangle()
///     .aspectRatio(3/4, contentMode: .fit)
///     .ignoresSafeArea()
/// ```
///
/// However, this may lead to a wrong aspect ratio because it only respects areas within the safe area region when calculating the aspect ratio.
/// Even if you swap the order of the modifiers, it produces unexpected behaviors if you put it inside a layout container (e.g. `VStack`, `HStack`, etc.)
///
/// Adopt this view modifier if you want to make sure the aspect ratio and want to ignore safe areas.
/// It works well for all senerios, making sure your aspect ratio never change even if you ignored safe areas on specific edges.
@_spi(Internal)
public struct _FitAspectRatioViewModifier: ViewModifier {
    var aspectRatio: CGFloat
    var ignoreSafeAreaEdges: Edge.Set
    @State var extraPaddings = CGSize(width: 0, height: 0)
    @State private var extraPaddingsCalculationTask: Task<Void, Error>?
    
    nonisolated public init(_ aspectRatio: CGFloat, ignoreSafeAreaEdges: Edge.Set) {
        self.aspectRatio = aspectRatio
        self.ignoreSafeAreaEdges = ignoreSafeAreaEdges
    }
    
    struct SizeAndSafeAreaInsets: Equatable {
        var size: CGSize
        var safeAreaInsets: EdgeInsets
    }
    
    public func body(content: Content) -> some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .ignoresSafeArea(edges: ignoreSafeAreaEdges)
            .overlay {
                content
                    .ignoresSafeArea(edges: ignoreSafeAreaEdges)
                    .padding(.bottom, -extraPaddings.height)
                    .padding(.trailing, -extraPaddings.width)
            }
            .background {
                GeometryReader { proxy in
                    let sizeAndInsets = SizeAndSafeAreaInsets(
                        size: proxy.size,
                        safeAreaInsets: proxy.safeAreaInsets
                    )
                    Rectangle()
                        .fill(.clear)
                        .onChange(of: sizeAndInsets, initial: true) {
                            updatePaddings(
                                aspectRatio: aspectRatio,
                                size: proxy.size,
                                safeAreaInsets: proxy.safeAreaInsets,
                                extraPaddings: extraPaddings
                            )
                        }
                }
            }
            .padding(.bottom, extraPaddings.height)
            .padding(.trailing, extraPaddings.width)
    }
    
    private func updatePaddings(
        aspectRatio: CGFloat,
        size: CGSize,
        safeAreaInsets: EdgeInsets,
        extraPaddings: CGSize
    ) {
        var safeAreaInsetsIgnoredSize = CGSize(
            width: size.width,
            height: size.height,
        )
        if ignoreSafeAreaEdges.contains(.leading) {
            safeAreaInsetsIgnoredSize.width += safeAreaInsets.leading
        }
        if ignoreSafeAreaEdges.contains(.bottom) {
            safeAreaInsetsIgnoredSize.width += safeAreaInsets.bottom
        }
        if ignoreSafeAreaEdges.contains(.trailing) {
            safeAreaInsetsIgnoredSize.width += safeAreaInsets.trailing
        }
        if ignoreSafeAreaEdges.contains(.top) {
            safeAreaInsetsIgnoredSize.width += safeAreaInsets.top
        }
        let currentAspectRatio = safeAreaInsetsIgnoredSize.width / safeAreaInsetsIgnoredSize.height
        
        let delta = abs(currentAspectRatio - aspectRatio)
        guard delta > 2e-2 else { return }
        
        var extraPaddings = CGSize.zero
        if safeAreaInsetsIgnoredSize.width < safeAreaInsetsIgnoredSize.height {
            let targetHeight = Double(safeAreaInsetsIgnoredSize.width) / Double(aspectRatio)
            extraPaddings.width = 0
            extraPaddings.height = abs(targetHeight - safeAreaInsetsIgnoredSize.height)
        } else {
            let targetWidth = Double(safeAreaInsetsIgnoredSize.height) * Double(aspectRatio)
            extraPaddings.width = abs(targetWidth - safeAreaInsetsIgnoredSize.width)
            extraPaddings.height = 0
        }
        
        let extraPaddingsDelta = CGSize(
            width: abs(extraPaddings.width - self.extraPaddings.width),
            height: abs(extraPaddings.height - self.extraPaddings.height)
        )
        if extraPaddingsDelta.width < 1 && extraPaddingsDelta.height < 1 {
            return
        }
        
        self.extraPaddings = extraPaddings
    }
}
