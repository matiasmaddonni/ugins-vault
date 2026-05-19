//
//  ShimmerBar.swift
//  UginsVault — UI: Components
//
//  Thin gold sweep used on splash and as a skeleton placeholder.
//

import SwiftUI

public struct ShimmerBar: View {

    @State private var phase: CGFloat = -1

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.uv.stroke)
                Capsule()
                    .fill(LinearGradient(
                        colors: [.clear, Color.uv.gold, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: w * 0.5)
                    .offset(x: phase * w)
            }
            .clipShape(Capsule())
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
}
