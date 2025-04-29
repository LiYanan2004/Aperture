import SwiftUI

extension View {
    /// Sets the style for buttons within this view to a button style with a responsive button style.
    /// - parameters:
    ///     - minimumScale: The minimum scaling factor to reflect pressing state when user press the button.
    ///     - onPressingChanged: The action to perform when pressing state changes.
    package func responsiveButton(
        minimumScale: CGFloat = 0.9,
        onPressingChanged: ((Bool) -> Void)? = nil
    ) -> some View {
        buttonStyle(
            .responsive(
                minimumScale: minimumScale,
                onPressingChanged: onPressingChanged
            )
        )
    }
}

/// A button style that feels responsive by scaling its content when user press it.
package struct ResponsiveButtonStyle: PrimitiveButtonStyle {
    /// The minimum scaling factor to reflect pressing state when user press the button.
    var minimumScale: CGFloat
    /// The action to perform when pressing state changes.
    var onPressingChanged: ((Bool) -> Void)?
    
    @Environment(\.isEnabled) private var isEnabled
    @GestureState(resetTransaction: .init(animation: .smooth(duration: 0.2)))
    private var scale = CGFloat(1)
    @State private var isPressing = false
    @State private var labelSize = CGSize.zero
    /// Ignore dragging updates if drag translation exceeds the thresholds.
    @State private var ignoreChanges = false
    
    /// Creates a reponsive button style.
    /// - parameters:
    ///     - minimumScale: The minimum scaling factor to reflect pressing state when user press the button.
    ///     - onPressingChanged: The action to perform when pressing state changes.
    package init(minimumScale: CGFloat = 0.9, onPressingChanged: ((Bool) -> Void)? = nil) {
        self.minimumScale = minimumScale
        self.onPressingChanged = onPressingChanged
    }
    
    package func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale)
            .onGeometryChange(for: CGSize.self) { geometry in
                geometry.size
            } action: { size in
                self.labelSize = size
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($scale) { dragging, scale, transaction in
                        guard isEnabled else { return }
                        guard !ignoreChanges else { return }
                        
                        // Check whether current location is out of bounds.
                        let location = dragging.location
                        let rect = CGRect(
                            x: -70,
                            y: -70,
                            width: labelSize.width + 140,
                            height: labelSize.height + 140
                        )
                        if rect.contains(location) == false {
                            transaction.animation = .smooth(duration: 0.2)
                            scale = 1
                            ignoreChanges = true // Ignore further updates.
                            isPressing = false
                            return
                        }
                        
                        transaction.animation = .snappy(duration: 0.3)
                        scale = minimumScale
                        isPressing = true
                    }
                    .onEnded { _ in
                        defer {
                            isPressing = false
                            ignoreChanges = false
                        }
                        guard !ignoreChanges else { return }
                        guard isEnabled else { return }
                        configuration.trigger()
                    }
            )
            .onChange(of: isPressing) { onPressingChanged?(isPressing) }
    }
}

extension PrimitiveButtonStyle where Self == ResponsiveButtonStyle {
    /// A button style that feels responsive by scaling its content when user press it.
    static package var responsive: ResponsiveButtonStyle { .init() }
    
    /// A button style that feels responsive by scaling its content when user press it.
    /// - parameters:
    ///     - minimumScale: The minimum scaling factor to reflect pressing state when user press the button.
    ///     - onPressingChanged: The action to perform when pressing state changes.
    static package func responsive(minimumScale: CGFloat = 0.9, onPressingChanged: ((Bool) -> Void)? = nil) -> ResponsiveButtonStyle {
        .init(minimumScale: minimumScale, onPressingChanged: onPressingChanged)
    }
}

#Preview {
    @Previewable @State var disabled = false
    
    Button {
        print("Action Triggered")
        disabled.toggle()
    } label: {
        Circle()
            .frame(width: 60, height: 60)
    }
    .responsiveButton { pressing in
        print("isPressing:", pressing)
    }
    .background {
        Circle()
            .stroke(lineWidth: 4)
            .frame(width: 68, height: 68)
    }
    .disabled(disabled)
}
