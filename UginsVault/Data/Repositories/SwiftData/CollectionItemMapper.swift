//
//  CollectionItemMapper.swift
//  UginsVault — Data layer / SwiftData
//

import Foundation

extension CollectionItem {

    init(from model: SwiftDataCollectionItem) {
        self.init(
            id: model.id,
            cardID: model.cardID,
            stackID: model.stackID,
            quantity: model.quantity,
            finish: Finish(rawValue: model.finishRaw) ?? .nonfoil,
            condition: CardCondition(rawValue: model.conditionRaw) ?? .nearMint,
            language: model.language,
            acquiredAt: model.acquiredAt,
            notes: model.notes
        )
    }
}

extension SwiftDataCollectionItem {

    convenience init(from item: CollectionItem) {
        self.init(
            id: item.id,
            cardID: item.cardID,
            stackID: item.stackID,
            quantity: item.quantity,
            finishRaw: item.finish.rawValue,
            conditionRaw: item.condition.rawValue,
            language: item.language,
            acquiredAt: item.acquiredAt,
            notes: item.notes
        )
    }

    func apply(_ item: CollectionItem) {
        cardID       = item.cardID
        stackID      = item.stackID
        quantity     = item.quantity
        finishRaw    = item.finish.rawValue
        conditionRaw = item.condition.rawValue
        language     = item.language
        acquiredAt   = item.acquiredAt
        notes        = item.notes
    }
}
