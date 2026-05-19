//
//  SparklinePathTests.swift
//  UginsVaultTests
//

import Foundation
import CoreGraphics
import Testing
@testable import UginsVault

@Suite("SparklinePath")
struct SparklinePathTests {

    private let size = CGSize(width: 100, height: 50)

    @Test("Empty input → no points")
    func emptyInput() {
        #expect(SparklinePath.points(for: [], in: size).isEmpty)
    }

    @Test("Single point → centered (50, 25)")
    func singlePoint() {
        let out = SparklinePath.points(for: [Decimal(10)], in: size)
        #expect(out.count == 1)
        #expect(out[0].x == 50)
        #expect(out[0].y == 25)
    }

    @Test("All-equal input renders a flat line at vertical centre — no divide-by-zero")
    func allEqualValues() {
        let out = SparklinePath.points(for: [Decimal(5), Decimal(5), Decimal(5)], in: size)
        #expect(out.count == 3)
        let ys = Set(out.map { $0.y })
        #expect(ys.count == 1)
        // 0.5 maps to (1 - (0.5 * 0.92 + 0.04)) * height = 0.5 * 50 = 25
        #expect(ys.first == 25)
    }

    @Test("Min and max map to the inner-padded extremes (4% top + bottom)")
    func minMaxMapping() {
        let out = SparklinePath.points(for: [Decimal(0), Decimal(10)], in: size)
        // index 0 → x = 0, value 0 → y near bottom; index 1 → x = width, value max → y near top
        #expect(out[0].x == 0)
        #expect(out[1].x == 100)
        // Padded 4% top + bottom; allow tolerance
        #expect(out[0].y > out[1].y)
        #expect(out[0].y > size.height * 0.9)
        #expect(out[1].y < size.height * 0.1)
    }

    @Test("Negative values are mapped relative to the series' own min/max")
    func negativeValuesNormaliseRelatively() {
        let out = SparklinePath.points(for: [Decimal(-10), Decimal(0), Decimal(10)], in: size)
        #expect(out.count == 3)
        // Lowest sits below the mid; highest above.
        #expect(out[0].y > out[1].y)
        #expect(out[1].y > out[2].y)
    }

    @Test("Zero-size canvas → no points (no negative-frame crash)")
    func zeroSizeCanvas() {
        let out = SparklinePath.points(for: [Decimal(1), Decimal(2)], in: .zero)
        #expect(out.isEmpty)
    }

    @Test("smoothPath through 3+ points returns a non-empty path")
    func smoothPathProducesPath() {
        let points = SparklinePath.points(for: [Decimal(1), Decimal(5), Decimal(3)], in: size)
        let path = SparklinePath.smoothPath(through: points)
        #expect(!path.isEmpty)
    }
}
