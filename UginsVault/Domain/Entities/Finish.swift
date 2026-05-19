//
//  Finish.swift
//  UginsVault — Domain layer
//
//  Physical finish of a card printing. A single printing usually ships
//  in multiple finishes (e.g. `nonfoil` + `foil`).
//

import Foundation

public enum Finish: String, Codable, CaseIterable, Sendable {
    case nonfoil
    case foil
    case etched

    public var displayName: String {
        switch self {
        case .nonfoil: return "Non-foil"
        case .foil:    return "Foil"
        case .etched:  return "Etched"
        }
    }
}
