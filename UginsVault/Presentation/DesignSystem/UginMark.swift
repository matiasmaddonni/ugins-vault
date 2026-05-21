//
//  UginMark.swift
//  UginsVault — UI: Brand mark
//
//  The Ugin's Vault brand mark — the "Spectral Core" hedron. Backed by the
//  `SpectralCore` image asset (transparent PNG with the cyan glow halo baked
//  in), scaled to the requested size.
//

import SwiftUI

public struct UginMark: View {

    public var size: CGFloat

    public init(size: CGFloat = 80) {
        self.size = size
    }

    public var body: some View {
        Image(.spectralCore)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    UginMark(size: 120)
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.uv.bg)
        .preferredColorScheme(.dark)
}
