//
//  UserProfileRepository.swift
//  UginsVault — Domain layer
//
//  Persists and exposes the local user's identity (name, monogram tint,
//  member-since year). Multi-user support is a non-goal for v1 — this
//  protocol exists so the persistence engine can swap without touching
//  Settings consumers.
//

import Foundation
import Observation

public protocol UserProfileRepository: AnyObject, Observable {

    var profile: UserProfile { get }

    func save(_ profile: UserProfile)
}
