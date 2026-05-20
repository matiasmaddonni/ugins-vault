//
//  UserProfile.swift
//  UginsVault — Domain layer
//
//  The local user's identity surfaced in Settings. Single-user app for now;
//  the entity is shaped so multi-user is a non-breaking change later.
//

import Foundation

public struct UserProfile: Codable, Equatable, Sendable {

    public var name: String
    public var monogramTint: MonogramTint
    public var memberSince: Int      // 4-digit year, e.g. 2026
    public var avatarFilename: String?

    public init(
        name: String,
        monogramTint: MonogramTint,
        memberSince: Int,
        avatarFilename: String? = nil
    ) {
        self.name = name
        self.monogramTint = monogramTint
        self.memberSince = memberSince
        self.avatarFilename = avatarFilename
    }

    /// Single uppercase letter used for the avatar fallback.
    public var monogram: String {
        let first = name.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? "·"
        return first.uppercased()
    }

    public static let `default` = UserProfile(
        name: "Matías",
        monogramTint: .gold,
        memberSince: 2026
    )
}

public enum MonogramTint: String, Codable, CaseIterable, Identifiable, Sendable {
    case gold
    case lavender
    case verdant
    case crimson
    case mist

    public var id: String { rawValue }
}
