//
//  DeckListParser.swift
//  UginsVault — Domain layer
//
//  Parses a pasted deck list — Moxfield / Arena / MTGO style — into
//  structured `ParsedDeckLine` rows the importer can resolve against
//  Scryfall.
//
//  Accepted line shapes:
//   • `4 Lightning Bolt`
//   • `4x Lightning Bolt`
//   • `1 Sol Ring (CMM) 410`
//   • `1x Sol Ring (CMM) 410 *F*`
//   • `// comments`, `Sideboard` headers, blank lines → ignored
//
//  Pure Swift — no Foundation regex dialects beyond NSRegularExpression
//  via `String.firstMatch(of:)` (Swift Regex literals, iOS 16+).
//

import Foundation

public struct ParsedDeckLine: Equatable, Sendable {

    public let quantity: Int
    public let name: String
    public let setCode: String?
    public let collectorNumber: String?
    public let isFoil: Bool

    public init(
        quantity: Int,
        name: String,
        setCode: String? = nil,
        collectorNumber: String? = nil,
        isFoil: Bool = false
    ) {
        self.quantity = quantity
        self.name = name
        self.setCode = setCode
        self.collectorNumber = collectorNumber
        self.isFoil = isFoil
    }
}

public enum DeckListParser {

    /// Splits the input by newlines and parses each non-empty,
    /// non-comment line into a `ParsedDeckLine`. Once a "stop section"
    /// header (SIDEBOARD / MAYBEBOARD / CONSIDERING / TOKENS) is hit,
    /// every subsequent line is skipped — those lists never belong in
    /// the imported stack.
    public static func parse(_ source: String) -> [ParsedDeckLine] {
        var results: [ParsedDeckLine] = []
        var stopped = false

        for raw in source.split(whereSeparator: \.isNewline) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Comments — Moxfield uses leading `//` for comments (e.g.
            // `// 7 mana value or higher`) and sometimes for section
            // headers like `//SIDEBOARD`. Strip the prefix + retest as
            // a section header before dropping.
            let stripped = trimmed.hasPrefix("//")
                ? String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                : trimmed

            if isStopSection(stripped) {
                stopped = true
                continue
            }
            if stopped { continue }

            if trimmed.hasPrefix("//") && !isDoubleFacedName(trimmed) { continue }
            guard !isSectionHeader(stripped) else { continue }

            if let parsed = parseLine(stripped) {
                results.append(parsed)
            }
        }

        return results
    }

    // MARK: - Per-line

    private static func parseLine(_ line: String) -> ParsedDeckLine? {
        var remaining = line

        // 1. Quantity prefix (`4`, `4x`, `4X`, optional). Default to 1
        //    when omitted (Moxfield commander row).
        let qty: Int
        if let (n, rest) = stripQuantity(remaining) {
            qty = n
            remaining = rest
        } else {
            qty = 1
        }

        // 2. Foil suffix `*F*` (Moxfield).
        var isFoil = false
        if let foilRange = remaining.range(of: "*F*", options: .caseInsensitive) {
            isFoil = true
            remaining.removeSubrange(foilRange)
            remaining = remaining.trimmingCharacters(in: .whitespaces)
        }

        // 3. Trailing collector number — last whitespace-separated token
        //    that's *numeric or alphanumeric* and follows a `(SET)` block.
        var setCode: String? = nil
        var collectorNumber: String? = nil

        if let (code, rest) = stripSetCode(remaining) {
            setCode = code
            remaining = rest

            if let (num, rest2) = stripTrailingCollectorNumber(remaining) {
                collectorNumber = num
                remaining = rest2
            }
        }

        let name = remaining.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, qty > 0 else { return nil }

        return ParsedDeckLine(
            quantity: qty,
            name: name,
            setCode: setCode,
            collectorNumber: collectorNumber,
            isFoil: isFoil
        )
    }

    // MARK: - Helpers

    private static func isSectionHeader(_ line: String) -> Bool {
        // Strip a trailing colon + lowercase + trim — handles
        // "SIDEBOARD:", "Commander :", "Maybeboard" all in one shape.
        let key = line
            .trimmingCharacters(in: CharacterSet(charactersIn: ": "))
            .lowercased()
        let headers: Set<String> = [
            "commander", "companion", "deck", "main"
        ]
        return headers.contains(key) || isStopSection(line)
    }

    /// Section headers that signal "everything below this is NOT part
    /// of the main deck" — sideboards, considering lists, token sheets,
    /// etc. Hitting one of these stops parsing for the rest of the file.
    private static func isStopSection(_ line: String) -> Bool {
        let key = line
            .trimmingCharacters(in: CharacterSet(charactersIn: ": "))
            .lowercased()
        let stops: Set<String> = [
            "sideboard", "maybeboard", "considering", "tokens"
        ]
        return stops.contains(key)
    }

    /// Returns `true` if the line is a card name that *starts* with `//`
    /// — never happens in practice, kept as a guardrail so future card
    /// names with leading slashes don't get eaten by the comment filter.
    private static func isDoubleFacedName(_ line: String) -> Bool {
        // Comments in Moxfield exports are `// foo`. A card-name line
        // that legitimately starts with `//` doesn't exist; this stays
        // a defensive `false` until we see a counterexample.
        false
    }

    /// Tries to strip a leading `<n>` or `<n>x`/`<n>X` quantity token.
    /// Returns `(quantity, remainingString)` on success.
    private static func stripQuantity(_ line: String) -> (Int, String)? {
        var chars = Substring(line)
        var digits = ""
        while let c = chars.first, c.isNumber {
            digits.append(c)
            chars = chars.dropFirst()
        }
        guard !digits.isEmpty, let qty = Int(digits) else { return nil }

        // Optional `x` separator.
        if let first = chars.first, first == "x" || first == "X" {
            chars = chars.dropFirst()
        }
        // Need at least one whitespace between qty and name.
        guard let first = chars.first, first.isWhitespace else { return nil }
        let rest = chars.drop(while: \.isWhitespace)
        return (qty, String(rest))
    }

    /// Tries to strip a `(XYZ)` set-code parenthetical anywhere in the
    /// trailing tokens. Returns `(setCode, remainingString)` on success.
    private static func stripSetCode(_ line: String) -> (String, String)? {
        guard let open = line.lastIndex(of: "("),
              let close = line.lastIndex(of: ")"),
              open < close
        else { return nil }

        let code = String(line[line.index(after: open)..<close])
            .trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, code.count <= 6 else { return nil }

        var remaining = line
        remaining.removeSubrange(open...close)
        return (code.lowercased(), remaining.trimmingCharacters(in: .whitespaces))
    }

    /// Strips the trailing whitespace-separated token if it looks like a
    /// collector number. Scryfall stores them as free-form strings, so
    /// we accept any token that contains at least one digit and isn't
    /// purely alphabetic — covers `153`, `12a`, `350★`, `90s`, `241p`,
    /// `STX-188` (PLST), etc.
    private static func stripTrailingCollectorNumber(_ line: String) -> (String, String)? {
        let tokens = line.split(separator: " ", omittingEmptySubsequences: true)
        guard let last = tokens.last else { return nil }
        guard last.contains(where: \.isNumber) else { return nil }

        let num = String(last)
        let rest = tokens.dropLast().joined(separator: " ")
        return (num, rest)
    }
}
