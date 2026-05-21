//
//  PriceStatusSource.swift
//  UginsVault — Domain layer
//
//  Reads server-side pricing progress (`/v1/prices/status`). The concrete
//  implementation (`APIPriceStatusSource`) lives in Data.
//

import Foundation

public protocol PriceStatusSource: Sendable {

    /// Current pricing progress for the caller's owned set.
    func status() async throws -> PriceStatus
}
