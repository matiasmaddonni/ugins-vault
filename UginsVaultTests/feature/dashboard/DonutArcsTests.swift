//
//  DonutArcsTests.swift
//  UginsVaultTests
//

import Foundation
import SwiftUI
import Testing
@testable import UginsVault

@Suite("DonutArcs")
struct DonutArcsTests {

    private func slice(_ id: String, _ value: Decimal) -> FormatSlice {
        FormatSlice(id: id, displayName: id, valueUSD: value, colorHex: 0xFFFFFF)
    }

    @Test("Empty input → no arcs")
    func emptyInput() {
        #expect(DonutArcs.arcs(for: []).isEmpty)
    }

    @Test("Single non-zero slice wraps the full circle")
    func singleSlice() {
        let arcs = DonutArcs.arcs(for: [slice("a", 10)])
        #expect(arcs.count == 1)
        let sweep = arcs[0].end.degrees - arcs[0].start.degrees
        #expect(abs(sweep - 360) < 0.001)
    }

    @Test("Angles sum to 360° across multiple slices")
    func anglesSumTo360() {
        let arcs = DonutArcs.arcs(for: [
            slice("a", 10),
            slice("b", 20),
            slice("c", 70)
        ])
        let totalSweep = arcs.reduce(0.0) { $0 + ($1.end.degrees - $1.start.degrees) }
        #expect(abs(totalSweep - 360) < 0.001)
    }

    @Test("Zero-value slices are skipped")
    func zeroSliceSkipped() {
        let arcs = DonutArcs.arcs(for: [
            slice("a", 10),
            slice("zero", 0),
            slice("b", 30)
        ])
        #expect(arcs.count == 2)
        #expect(arcs.map(\.id) == ["a", "b"])
    }

    @Test("Order is preserved across the result")
    func orderPreserved() {
        let arcs = DonutArcs.arcs(for: [
            slice("first",  10),
            slice("second", 20),
            slice("third",  30)
        ])
        #expect(arcs.map(\.id) == ["first", "second", "third"])
    }

    @Test("Sweep is proportional to value: a slice worth 25% covers 90°")
    func sweepIsProportional() {
        let arcs = DonutArcs.arcs(for: [
            slice("quarter", 25),
            slice("rest", 75)
        ])
        let quarterSweep = arcs[0].end.degrees - arcs[0].start.degrees
        #expect(abs(quarterSweep - 90) < 0.001)
    }
}
