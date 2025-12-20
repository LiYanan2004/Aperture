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

    public var body: some View {
        let mainContent = self.mainContent
        
        mainContent
            .matchedGeometryEffect(id: "main-content", in: accessoryContainer)
            .frame(
                maxWidth: proxy.secondaryLayoutStack.stack == .hstack ? .infinity : nil,
                maxHeight: proxy.secondaryLayoutStack.stack == .vstack ? .infinity : nil
            )
            .overlay(alignment: alignment) {
                _VariadicView.Tree(
                    _CameraStack(
                        spacing: spacing,
                        configuration: proxy.secondaryLayoutStack
                    )
                ) {
                    leadingAccessories
                    mainContent
                        .hidden()
                        .matchedGeometryEffect(id: "main-content", in: accessoryContainer, isSource: false)
                    trailingAccessories
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
