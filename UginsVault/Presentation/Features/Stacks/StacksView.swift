//
//  StacksView.swift
//  UginsVault — Presentation: Stacks
//
//  Placeholder. Real implementation lands in v0.3 alongside the `Stack`
//  domain entity (deck / binder / loan / sale / showcase / inbox).
//

import SwiftUI

public struct StacksView: View {

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.uv.bg.ignoresSafeArea()

                VStack(spacing: 14) {
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.uv.gold)

                    Text("Stacks")
                        .font(.uv.display(22, weight: .semibold))
                        .foregroundStyle(Color.uv.text)

                    Text("Decks, binders, loans, sales, showcase and inbox land here in v0.3.")
                        .font(.uv.body(13))
                        .foregroundStyle(Color.uv.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StacksView()
        .preferredColorScheme(.dark)
}
