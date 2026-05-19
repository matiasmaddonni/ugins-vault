//
//  ShareSheet.swift
//  UginsVault — Presentation: Design System
//
//  Thin wrapper around `UIActivityViewController` so we can drive a
//  native share sheet from a SwiftUI `.sheet(isPresented:)`. SwiftUI's
//  `ShareLink` works for static items only — wrapping the UIKit
//  controller lets us hand it a single computed `String` (the
//  decklist text) at the moment of presentation.
//

import SwiftUI
import UIKit

public struct ShareSheet: UIViewControllerRepresentable {

    public let text: String

    public init(text: String) {
        self.text = text
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    public func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
