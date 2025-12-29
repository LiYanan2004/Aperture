//
//  CameraAccessoryContainer.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import SwiftUI

/// A container that lays out main content based on current context and overlays the accessories in relatively-fixed edge.
///
/// Here is an example of placing ``CameraFlipButton`` and other controls besides ``CameraShutterButton``.
///
/// ```swift
/// CameraAdaptiveStack(camera: camera) { proxy in
///     CameraViewFinder(camera: camera, videoGravity: .fill)
///         .ignoresSafeArea()
///
///     CameraAccessoryContainer(proxy: proxy, spacing: 0) {
///         CameraShutterButton(
///             camera: camera,
///             action: saveCapturedPhoto
///         )
///     } trailingAccessories: {
///         Button {
///             captureLivePhoto.toggle()
///         } label: {
///             Label("Live Photo", systemImage: "livephoto")
///         }
///     }
/// }
/// .padding()
/// ```
public struct CameraAccessoryContainer<LeadingAccessories: View, Content: View, TrailingAccessories: View>: View {
    /// A proxy produced by ``CameraAdaptiveStack``.
    public var proxy: CameraAdaptiveStackProxy
    /// A value for aligning the subviews in this stack on both the x- and y-axes.
    public var alignment: Alignment
    /// A value indicates the spacing between the main content and accessory area.
    public var spacing: CGFloat?

    /// The view of the main content.
    @ViewBuilder public var content: Content
    /// A view of the accessories placed on the leading side.
    @ViewBuilder public var leadingAccessories: LeadingAccessories
    /// A view of the accessories placed on the trailing side.
    @ViewBuilder public var trailingAccessories: TrailingAccessories

    /// Creates an instance that lays out main content based on current context and overlays the accessories in relatively-fixed edge.
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
            .overlay(alignment: proxy.primaryLayoutStack.stack != .zstack ? .center : .top) {
                _VariadicView.Tree(
                    _CameraStack(
                        alignment: alignment,
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
                            minWidth: proxy.secondaryLayoutStack.order == .normal ? topLeftSizeArea.width : nil,
                            minHeight: proxy.secondaryLayoutStack.order == .normal ? topLeftSizeArea.height : nil
                        )
                    Color.clear
                        .frame(width: mainContentRect?.width, height: mainContentRect?.height)
                        .padding(spacing ?? .zero)
                    trailingAccessories
                        .adoptsProposedSize(
                            alignment: proxy.secondaryLayoutStack.order == .normal ? trailingAnchor : leadingAnchor,
                            isEnabled: isRegularLayout
                        )
                        .frame(
                            minWidth: proxy.secondaryLayoutStack.order == .reversed ? topLeftSizeArea.width : nil,
                            minHeight: proxy.secondaryLayoutStack.order == .reversed ? topLeftSizeArea.height : nil
                        )
                }
            }
            .coordinateSpace(name: accessoryContainer)
    }
    
    private var mainContent: some View {
        _VariadicView.Tree(
            _CameraStack(
                alignment: .center,
                spacing: spacing,
                configuration: proxy.secondaryLayoutStack
            )
        ) {
            content
        }
    }
}

extension CameraAccessoryContainer where LeadingAccessories == EmptyView {
    /// Creates an instance that lays out main content based on current context and overlays the accessories in relatively-fixed edge.
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
    /// Creates an instance that lays out main content based on current context and overlays the accessories in relatively-fixed edge.
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
