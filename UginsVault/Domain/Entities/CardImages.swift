//
//  CardImages.swift
//  UginsVault — Domain layer
//
//  Set of URLs Scryfall ships per card printing. `normal` is the canonical
//  list-row thumbnail; `large` / `png` are used in Card detail; `artCrop`
//  is reserved for hero / empty-state decoration.
//

import Foundation

public struct CardImages: Codable, Hashable, Sendable {

    public let small:      URL?
    public let normal:     URL?
    public let large:      URL?
    public let png:        URL?
    public let artCrop:    URL?
    public let borderCrop: URL?

    public init(
        small: URL? = nil,
        normal: URL? = nil,
        large: URL? = nil,
        png: URL? = nil,
        artCrop: URL? = nil,
        borderCrop: URL? = nil
    ) {
        self.small      = small
        self.normal     = normal
        self.large      = large
        self.png        = png
        self.artCrop    = artCrop
        self.borderCrop = borderCrop
    }

    /// Convenience pick for list rows.
    public var thumbnail: URL? { normal ?? small ?? large }

    /// Smallest art that still reads at list-row size. Prefer this on dense
    /// lists (collection, commander picker): `small` is ~146px vs `normal`'s
    /// ~488px, so the first decode is cheap and the cached bitmap is tiny.
    public var listThumbnail: URL? { small ?? normal ?? large }

    /// Convenience pick for detail screens.
    public var hero: URL? { large ?? png ?? normal ?? small }
}
