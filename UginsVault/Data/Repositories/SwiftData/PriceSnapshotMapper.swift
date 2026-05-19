//
//  PriceSnapshotMapper.swift
//  UginsVault — Data layer / SwiftData
//
//  Bidirectional translation between Domain `PriceSnapshot` (value)
//  and `SwiftDataPriceSnapshot` (`@Model` reference).
//

import Foundation

extension PriceSnapshot {

    init?(from model: SwiftDataPriceSnapshot) {
        guard
            let source = PriceSource(rawValue: model.sourceRaw),
            let currency = Currency(rawValue: model.currencyRaw)
        else { return nil }

        self.init(
            id: model.id,
            cardID: model.cardID,
            source: source,
            date: model.date,
            currency: currency,
            retail: model.retail
        )
    }
}

extension SwiftDataPriceSnapshot {

    convenience init(from snapshot: PriceSnapshot) {
        self.init(
            id: snapshot.id,
            cardID: snapshot.cardID,
            sourceRaw: snapshot.source.rawValue,
            date: snapshot.date,
            currencyRaw: snapshot.currency.rawValue,
            retail: snapshot.retail
        )
    }

    func apply(_ snapshot: PriceSnapshot) {
        cardID      = snapshot.cardID
        sourceRaw   = snapshot.source.rawValue
        date        = snapshot.date
        currencyRaw = snapshot.currency.rawValue
        retail      = snapshot.retail
    }
}
