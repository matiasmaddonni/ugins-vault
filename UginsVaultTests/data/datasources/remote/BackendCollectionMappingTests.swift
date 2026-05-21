//
//  BackendCollectionMappingTests.swift
//  UginsVaultTests — Data / Backend
//

import Foundation
import Testing
@testable import UginsVault

@Suite("Backend collection DTO mapping")
struct BackendCollectionMappingTests {

    // MARK: - Stack

    @Test("Stack round-trips through its DTO (opaque enums as rawValues)")
    func stackRoundTrips() {
        let stack = Stack(
            id: UUID(),
            name: "Sale pile",
            kind: .sale,
            sortOrder: 3,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            format: .commander,
            colors: [.white, .blue],
            commander: "Kytheon",
            commanderCardID: UUID(),
            person: "Bob",
            since: Date(timeIntervalSince1970: 1_700_100_000)
        )

        let dto = StackDTO(stack)
        #expect(dto.kind == "sale")
        #expect(dto.format == "commander")
        #expect(Set(dto.colors) == ["W", "U"])

        #expect(dto.toDomain() == stack)
    }

    @Test("Unknown opaque stack values fall back safely")
    func stackFallbacks() {
        let dto = StackDTO(
            id: UUID(),
            name: "Mystery",
            kind: "teleporter",          // unknown -> .inbox
            sortOrder: 0,
            createdAt: Date(),
            format: "pakistanibrawl",    // unknown -> nil
            colors: ["W", "Z"],          // Z unknown -> dropped
            commander: nil,
            commanderCardId: nil,
            person: nil,
            since: nil
        )

        let stack = dto.toDomain()
        #expect(stack.kind == .inbox)
        #expect(stack.format == nil)
        #expect(stack.colors == [.white])
    }

    // MARK: - CollectionItem

    @Test("CollectionItem round-trips through its DTO")
    func itemRoundTrips() {
        let item = CollectionItem(
            id: UUID(),
            cardID: UUID(),
            stackID: UUID(),
            quantity: 4,
            finish: .foil,
            condition: .lightlyPlayed,
            language: "es",
            acquiredAt: Date(timeIntervalSince1970: 1_700_000_000),
            notes: "signed"
        )

        let dto = CollectionItemDTO(item)
        #expect(dto.finish == "foil")
        #expect(dto.condition == "LP")

        #expect(dto.toDomain() == item)
    }

    @Test("Unknown finish/condition fall back; quantity is clamped to >= 1")
    func itemFallbacks() {
        let dto = CollectionItemDTO(
            id: UUID(),
            cardId: UUID(),
            stackId: UUID(),
            quantity: 0,             // clamped -> 1
            finish: "rainbow",       // unknown -> .nonfoil
            condition: "pristine",   // unknown -> .nearMint
            language: "en",
            acquiredAt: nil,
            notes: nil
        )

        let item = dto.toDomain()
        #expect(item.quantity == 1)
        #expect(item.finish == .nonfoil)
        #expect(item.condition == .nearMint)
    }
}
