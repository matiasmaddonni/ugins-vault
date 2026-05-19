//
//  SkeletonBlock.swift
//  UginsVault — Presentation: Design System
//
//  Rectangular placeholder with a translating gradient. Used in
//  loading skeletons (currently: Dashboard first-fetch) so the screen
//  doesn't jump when real content lands.
//

import SwiftUI

public struct SkeletonBlock: View {

    public let cornerRadius: CGFloat
    @State private var offset: CGFloat = -0.6

    public init(cornerRadius: CGFloat = UVRadius.sm) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.uv.panelLo)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.uv.panelHi.opacity(0.65), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * 0.6)
                    .offset(x: offset * proxy.size.width)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    offset = 1.0
                }
            }
        }
    }
}
