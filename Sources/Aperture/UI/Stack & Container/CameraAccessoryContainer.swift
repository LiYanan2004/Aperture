//
//  CameraAccessoryContainer.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//


import SwiftUI

public struct CameraAccessoryContainer<LeadingAccessories: View, Content: View, TrailingAccessories: View>: View {
    public var proxy: CameraAdaptiveStackProxy
    public var alignment: Alignment
    public var spacing: CGFloat?

    @ViewBuilder public var content: Content
    @ViewBuilder public var leadingAccessories: LeadingAccessories
    @ViewBuilder public var trailingAccessories: TrailingAccessories

    public init(
        proxy: CameraAdaptiveStackProxy,
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder leadingAccessories: () -> LeadingAccessories,
        @ViewBuilder trailingAccessories: () -> TrailingAccessories
    ) {
        self.proxy = proxy
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
        self.leadingAccessories = leadingAccessories()
        self.trailingAccessories = trailingAccessories()
    }
    
    @Namespace private var accessoryContainer
    @State private var mainContentRect: CGRect?

    public var body: some View {
        self.mainContent
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named(accessoryContainer))
            } action: { rect in
                mainContentRect = rect
            }
            .frame(
                maxWidth: proxy.secondaryLayoutStack.stack == .hstack ? .infinity : nil,
                maxHeight: proxy.secondaryLayoutStack.stack == .vstack ? .infinity : nil
            )
            .coordinateSpace(name: accessoryContainer)
            .overlay(alignment: alignment) {
                _VariadicView.Tree(
                    _CameraStack(
                        spacing: 0,
                        configuration: proxy.secondaryLayoutStack
                    )
                ) {
                    let topLeftSizeArea = (
                        width: proxy.secondaryLayoutStack.stack == .hstack ? mainContentRect?.minX : mainContentRect?.width,
                        height: proxy.secondaryLayoutStack.stack == .hstack ? mainContentRect?.height : mainContentRect?.minY
                    )
                    let leadingAnchor = Alignment(
                        horizontal: proxy.secondaryLayoutStack.stack == .vstack ? .center : .leading,
                        vertical: proxy.secondaryLayoutStack.stack == .hstack ? .center : .top,
                    )
                    let trailingAnchor = Alignment(
                        horizontal: proxy.secondaryLayoutStack.stack == .vstack ? .center : .trailing,
                        vertical: proxy.secondaryLayoutStack.stack == .hstack ? .center : .bottom,
                    )
                    let isRegularLayout = proxy.primaryLayoutStack.stack != .zstack
                    leadingAccessories
                        .adoptsProposedSize(
                            alignment: proxy.secondaryLayoutStack.order == .normal ? leadingAnchor : trailingAnchor,
                            isEnabled: isRegularLayout
                        )
                        .frame(
                            idealWidth: proxy.secondaryLayoutStack.order == .normal ? topLeftSizeArea.width : nil,
                            idealHeight: proxy.secondaryLayoutStack.order == .normal ? topLeftSizeArea.height : nil
                        )
                        .fixedSize(
                            horizontal: proxy.secondaryLayoutStack.order == .normal && isRegularLayout,
                            vertical: proxy.secondaryLayoutStack.order == .normal && isRegularLayout
                        )
                    EmptyView()
                        .adoptsProposedSize(isEnabled: isRegularLayout)
                        .frame(width: mainContentRect?.width, height: mainContentRect?.height)
                        .padding(spacing ?? .zero)
                    trailingAccessories
                        .adoptsProposedSize(
                            alignment: proxy.secondaryLayoutStack.order == .normal ? trailingAnchor : leadingAnchor,
                            isEnabled: isRegularLayout
                        )
                        .frame(
                            idealWidth: proxy.secondaryLayoutStack.order == .reversed ? topLeftSizeArea.width : nil,
                            idealHeight: proxy.secondaryLayoutStack.order == .reversed ? topLeftSizeArea.height : nil
                        )
                        .fixedSize(
                            horizontal: proxy.secondaryLayoutStack.order == .reversed && isRegularLayout,
                            vertical: proxy.secondaryLayoutStack.order == .reversed && isRegularLayout
                        )
                }
            }
    }
    
    private var mainContent: some View {
        _VariadicView.Tree(
            _CameraStack(
                spacing: spacing,
                configuration: proxy.secondaryLayoutStack
            )
        ) {
            content
        }
    }
}

extension CameraAccessoryContainer where LeadingAccessories == EmptyView {
    public init(
        proxy: CameraAdaptiveStackProxy,
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailingAccessories: () -> TrailingAccessories
    ) {
        self.init(
            proxy: proxy,
            alignment: alignment,
            spacing: spacing,
            content: content
        ) {
            EmptyView()
        } trailingAccessories: {
            trailingAccessories()
        }
    }
}

extension CameraAccessoryContainer where TrailingAccessories == EmptyView {
    public init(
        proxy: CameraAdaptiveStackProxy,
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder leadingAccessories: () -> LeadingAccessories
    ) {
        self.init(
            proxy: proxy,
            alignment: alignment,
            spacing: spacing,
            content: content
        ) {
           leadingAccessories()
        } trailingAccessories: {
            EmptyView()
        }
    }
}
