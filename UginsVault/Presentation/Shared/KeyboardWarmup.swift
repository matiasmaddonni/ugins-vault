//
//  KeyboardWarmup.swift
//  UginsVault — Presentation: Shared
//
//  Cold-starts the iOS text-input + keyboard subsystem so the user's
//  first tap on a `.searchable` field doesn't sit through the 1–2 s
//  initialisation pause on the main thread. We add an off-screen
//  `UITextField`, briefly make it first responder, then drop it. iOS
//  caches the keyboard runtime — the next real field focuses
//  immediately.
//
//  Call once after the tabs are on screen (e.g. from
//  `MainTabView.runBootstrap`). Cheap (~ms) and silent.
//

import UIKit

@MainActor
public enum KeyboardWarmup {

    private static var didWarm = false

    public static func prepare() {
        guard !didWarm else { return }
        didWarm = true

        guard
            let window = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first
        else { return }

        let field = UITextField(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.isHidden = true
        window.addSubview(field)

        // Becoming first responder triggers the keyboard subsystem warm-up
        // (text-input client, autocorrect engine, etc.). Resigning right
        // away keeps it invisible to the user — iOS keeps the runtime
        // resident so the next real focus is instant.
        field.becomeFirstResponder()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            field.resignFirstResponder()
            field.removeFromSuperview()
        }
    }
}
