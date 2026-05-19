//
//  UserDefaultsUserProfileRepository.swift
//  UginsVault — Data layer
//
//  Persists `UserProfile` as a JSON blob in `UserDefaults`. Swapping to
//  Keychain or SwiftData later only touches this file.
//

import Foundation
import Observation

@Observable
public final class UserDefaultsUserProfileRepository: UserProfileRepository {

    private enum Key {
        static let profile = "uv.profile"
    }

    public private(set) var profile: UserProfile

    @ObservationIgnored private let storage: SessionStorageDataSource
    @ObservationIgnored private let decoder = JSONDecoder()
    @ObservationIgnored private let encoder = JSONEncoder()

    public init(storage: SessionStorageDataSource) {
        self.storage = storage
        self.profile = Self.read(from: storage, decoder: decoder)
    }

    public func save(_ profile: UserProfile) {
        self.profile = profile
        guard
            let data = try? encoder.encode(profile),
            let raw = String(data: data, encoding: .utf8)
        else { return }

        storage.set(raw, forKey: Key.profile)
    }

    private static func read(from storage: SessionStorageDataSource, decoder: JSONDecoder) -> UserProfile {
        guard
            let raw = storage.string(forKey: Key.profile),
            let data = raw.data(using: .utf8),
            let profile = try? decoder.decode(UserProfile.self, from: data)
        else {
            return .default
        }
        return profile
    }
}
