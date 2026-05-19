//
//  PressableButtonStyle.swift
//  UginsVault — Presentation: Design System
//
//  Generic "press-down" feedback for any tappable container that isn't
//  already a system button: scale to 0.98 + slight brightness dip on
//  press, with a snappy spring return. Pair with `.buttonStyle(.pressable)`.
//

import SwiftUI

public struct PressableButtonStyle: ButtonStyle {

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(
                .spring(response: 0.28, dampingFraction: 0.85),
                value: configuration.isPressed
            )
    }
}

public extension ButtonStyle where Self == PressableButtonStyle {
    /// Press-down scale + brightness feedback. Use on row-level taps,
    /// hero cards, or any custom-shaped tappable surface.
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
