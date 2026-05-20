//
//  MTGJSONStreamingPriceParser.swift
//  UginsVault — Data layer / MTGJSON
//
//  Parses the FULL `AllPrices.json` (~1.2 GB) into a flat array of
//  `PriceSnapshot`s WITHOUT loading the structure into memory.
//  `JSONSerialization` would build a multi-GB object tree and jetsam
//  the app, so instead we memory-map the file and walk the top-level
//  `data` object byte-by-byte. For each `"<uuid>": { … }` entry we only
//  materialise the value sub-object when the uuid is in the owned
//  allow-list — every other card is skipped via a string-aware brace
//  scan. Peak resident memory stays at one card object + the (owned-
//  bounded) snapshot array.
//
//  The scanner is defensive: every branch advances the cursor, all
//  reads are bounds-checked, and malformed input simply stops the walk
//  early (returns whatever was parsed so far) — it can neither crash
//  nor hang.
//

import Foundation

public enum MTGJSONStreamingPriceParser {

    private static let knownSources: [(key: String, source: PriceSource)] = [
        ("cardkingdom", .cardkingdom),
        ("tcgplayer",   .tcgplayer),
        ("cardmarket",  .cardmarket)
    ]

    /// Streams `fileURL`, keeping only owned cards and (optionally) only
    /// dates on/after `windowStart`. The file is left untouched.
    public static func parse(
        fileURL: URL,
        ownedCardIDs: Set<UUID>,
        windowStart: Date? = nil
    ) throws -> [PriceSnapshot] {

        let allowed = Set(ownedCardIDs.map { $0.uuidString.lowercased() })
        guard !allowed.isEmpty else { return [] }

        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        var snapshots: [PriceSnapshot] = []
        snapshots.reserveCapacity(allowed.count * knownSources.count * 35)

        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            let count = raw.count
            guard var i = indexOfDataObjectOpen(base, count) else { return }
            i += 1 // step past the `{` of the data object

            while i < count {
                i = skipWhitespaceAndCommas(base, i, count)
                guard i < count else { break }
                if base[i] == 0x7D { break }            // `}` → end of data object
                guard base[i] == 0x22 else { break }     // expect a `"` key

                let (key, afterKey) = parseString(base, i, count)
                i = afterKey
                i = skipWhitespace(base, i, count)
                guard i < count, base[i] == 0x3A else { break }   // `:`
                i += 1
                i = skipWhitespace(base, i, count)

                let valueStart = i
                let valueEnd = skipValue(base, i, count)
                guard valueEnd > valueStart else { break }        // no progress → bail

                if let key, allowed.contains(key.lowercased()),
                   let uuid = UUID(uuidString: key) {
                    let slice = Data(bytes: base + valueStart, count: valueEnd - valueStart)
                    if let object = try? JSONSerialization.jsonObject(with: slice) as? [String: Any] {
                        extract(into: &snapshots, cardUUID: uuid, cardDict: object, windowStart: windowStart)
                    }
                }
                i = valueEnd
            }
        }

        return snapshots
    }

    // MARK: - Per-card extraction

    private static func extract(
        into snapshots: inout [PriceSnapshot],
        cardUUID: UUID,
        cardDict: [String: Any],
        windowStart: Date?
    ) {
        guard let paper = cardDict["paper"] as? [String: Any] else { return }
        for (sourceKey, sourceEnum) in knownSources {
            guard
                let sourceDict = paper[sourceKey] as? [String: Any],
                let retail = sourceDict["retail"] as? [String: Any]
            else { continue }

            let currency: Currency = {
                if let raw = sourceDict["currency"] as? String,
                   let parsed = Currency(rawValue: raw.uppercased()) {
                    return parsed
                }
                return sourceEnum.nativeCurrency
            }()

            for (dateString, price) in mergedFinishMap(retail: retail) {
                guard let date = dateFormatter.date(from: dateString) else { continue }
                if let windowStart, date < windowStart { continue }
                snapshots.append(
                    PriceSnapshot(
                        cardID: cardUUID,
                        source: sourceEnum,
                        date: date,
                        currency: currency,
                        retail: Decimal(price)
                    )
                )
            }
        }
    }

    private static func mergedFinishMap(retail: [String: Any]) -> [String: Double] {
        var merged: [String: Double] = [:]
        for finishKey in ["normal", "foil", "etched"] {
            guard let day = retail[finishKey] as? [String: Any] else { continue }
            for (dateString, priceAny) in day {
                let price: Double?
                if let value = priceAny as? Double { price = value }
                else if let number = priceAny as? NSNumber { price = number.doubleValue }
                else { price = nil }
                if let price, price > 0 { merged[dateString] = price }
            }
        }
        return merged
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - Byte scanner

    private static func indexOfDataObjectOpen(_ base: UnsafePointer<UInt8>, _ count: Int) -> Int? {
        // Search for the literal `"data"`, then the next `:` then `{`.
        let needle: [UInt8] = [0x22, 0x64, 0x61, 0x74, 0x61, 0x22] // "data"
        var i = 0
        let limit = count - needle.count
        while i <= limit {
            var matched = true
            for k in 0..<needle.count where base[i + k] != needle[k] {
                matched = false
                break
            }
            if matched {
                var j = i + needle.count
                j = skipWhitespace(base, j, count)
                guard j < count, base[j] == 0x3A else { i += 1; continue } // `:`
                j += 1
                j = skipWhitespace(base, j, count)
                if j < count, base[j] == 0x7B { return j }                 // `{`
            }
            i += 1
        }
        return nil
    }

    private static func isWhitespace(_ c: UInt8) -> Bool {
        c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D
    }

    private static func skipWhitespace(_ base: UnsafePointer<UInt8>, _ start: Int, _ count: Int) -> Int {
        var i = start
        while i < count, isWhitespace(base[i]) { i += 1 }
        return i
    }

    private static func skipWhitespaceAndCommas(_ base: UnsafePointer<UInt8>, _ start: Int, _ count: Int) -> Int {
        var i = start
        while i < count, isWhitespace(base[i]) || base[i] == 0x2C { i += 1 }
        return i
    }

    /// Returns the index just past the closing `"` of the string at
    /// `start` (which must point at the opening `"`).
    private static func skipString(_ base: UnsafePointer<UInt8>, _ start: Int, _ count: Int) -> Int {
        var i = start + 1
        var escaped = false
        while i < count {
            let c = base[i]
            if escaped { escaped = false }
            else if c == 0x5C { escaped = true }   // backslash
            else if c == 0x22 { return i + 1 }      // closing quote
            i += 1
        }
        return count
    }

    /// Decodes the string at `start` and returns it with the index just
    /// past its closing quote.
    private static func parseString(_ base: UnsafePointer<UInt8>, _ start: Int, _ count: Int) -> (String?, Int) {
        let end = skipString(base, start, count)
        let innerStart = start + 1
        let innerEnd = max(innerStart, end - 1)
        guard innerEnd > innerStart else { return (nil, end) }
        let string = String(decoding: UnsafeBufferPointer(start: base + innerStart, count: innerEnd - innerStart), as: UTF8.self)
        return (string, end)
    }

    /// Returns the index just past the JSON value at `start`
    /// (object / array / string / scalar).
    private static func skipValue(_ base: UnsafePointer<UInt8>, _ start: Int, _ count: Int) -> Int {
        guard start < count else { return count }
        let c = base[start]
        if c == 0x7B || c == 0x5B { return skipContainer(base, start, count) } // { or [
        if c == 0x22 { return skipString(base, start, count) }
        var i = start
        while i < count {
            let ch = base[i]
            if ch == 0x2C || ch == 0x7D || ch == 0x5D || isWhitespace(ch) { break }
            i += 1
        }
        return i
    }

    /// Returns the index just past the matching close of the container
    /// (`{`/`[`) at `start`. String-aware so braces inside strings don't
    /// throw off the depth count.
    private static func skipContainer(_ base: UnsafePointer<UInt8>, _ start: Int, _ count: Int) -> Int {
        var depth = 0
        var i = start
        var inString = false
        var escaped = false
        while i < count {
            let c = base[i]
            if inString {
                if escaped { escaped = false }
                else if c == 0x5C { escaped = true }
                else if c == 0x22 { inString = false }
            } else {
                if c == 0x22 { inString = true }
                else if c == 0x7B || c == 0x5B { depth += 1 }
                else if c == 0x7D || c == 0x5D {
                    depth -= 1
                    if depth == 0 { return i + 1 }
                }
            }
            i += 1
        }
        return count
    }
}
