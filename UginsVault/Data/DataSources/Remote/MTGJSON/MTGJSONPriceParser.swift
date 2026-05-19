//
//  MTGJSONPriceParser.swift
//  UginsVault — Data layer / MTGJSON
//
//  Turns an MTGJSON AllPricesToday.json on-disk dump into a flat
//  array of `PriceSnapshot`s, filtered by the user's owned card ids.
//
//  Strategy: load the whole top-level object via `JSONSerialization`
//  (faster than Codable for `[String: Any]`), then walk only the
//  buckets we care about (`paper.cardkingdom`, `paper.tcgplayer`,
//  `paper.cardmarket`) without materialising any other branch. Peak
//  memory ≈ 2× file size on the JSONSerialization tree, which is
//  acceptable on iOS 26 hardware (~100MB transient).
//
//  Foil + etched finishes are folded into the same daily price by
//  picking `etched` > `foil` > `normal` (foil tends to be the larger
//  number, but we'd rather miss an etched-only printing than crash).
//

import Foundation

public enum MTGJSONPriceParser {

    /// Sources we surface to the user. Anything else MTGJSON ships
    /// (cardhoarder, mtgo_traders, cardsphere) is skipped at parse.
    private static let knownSources: [(key: String, source: PriceSource)] = [
        ("cardkingdom", .cardkingdom),
        ("tcgplayer",   .tcgplayer),
        ("cardmarket",  .cardmarket)
    ]

    /// Reads `fileURL`, filters by `ownedCardIDs`, and returns a flat
    /// list of `PriceSnapshot`s. The file is left untouched — callers
    /// clean up.
    public static func parse(
        fileURL: URL,
        ownedCardIDs: Set<UUID>
    ) throws -> [PriceSnapshot] {

        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)

        let root: [String: Any]
        do {
            guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw MTGJSONError.parseFailed(message: "Root is not an object")
            }
            root = object
        } catch let error as MTGJSONError {
            throw error
        } catch {
            throw MTGJSONError.parseFailed(message: error.localizedDescription)
        }

        guard let cards = root["data"] as? [String: Any] else {
            throw MTGJSONError.parseFailed(message: "Missing `data` block")
        }

        let allowedKeys = Set(ownedCardIDs.map { $0.uuidString.lowercased() })
        var snapshots: [PriceSnapshot] = []
        snapshots.reserveCapacity(allowedKeys.count * knownSources.count * 30)

        for (uuidString, value) in cards where allowedKeys.contains(uuidString.lowercased()) {
            guard
                let cardUUID = UUID(uuidString: uuidString),
                let cardDict = value as? [String: Any],
                let paper = cardDict["paper"] as? [String: Any]
            else { continue }

            for (sourceKey, sourceEnum) in knownSources {
                guard
                    let sourceDict = paper[sourceKey] as? [String: Any],
                    let retail = sourceDict["retail"] as? [String: Any]
                else { continue }

                let currency: Currency = {
                    if let raw = sourceDict["currency"] as? String,
                       let c = Currency(rawValue: raw.uppercased()) {
                        return c
                    }
                    return sourceEnum.nativeCurrency
                }()

                let priceMap = mergedFinishMap(retail: retail)
                for (dateString, price) in priceMap {
                    guard let date = Self.dateFormatter.date(from: dateString) else { continue }
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

        return snapshots
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Folds the `normal` / `foil` / `etched` finish dicts into one
    /// `date → price` map. Later finishes win where dates overlap.
    private static func mergedFinishMap(retail: [String: Any]) -> [String: Double] {
        var merged: [String: Double] = [:]
        for finishKey in ["normal", "foil", "etched"] {
            guard let day = retail[finishKey] as? [String: Any] else { continue }
            for (dateString, priceAny) in day {
                let price: Double?
                if let d = priceAny as? Double { price = d }
                else if let n = priceAny as? NSNumber { price = n.doubleValue }
                else { price = nil }
                if let price, price > 0 {
                    merged[dateString] = price
                }
            }
        }
        return merged
    }
}
