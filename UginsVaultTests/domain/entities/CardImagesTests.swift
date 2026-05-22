//
//  CardImagesTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import Testing
@testable import UginsVault

@Suite("CardImages")
struct CardImagesTests {

    private func url(_ s: String) -> URL { URL(string: s)! }

    @Test("thumbnail prefers normal, then small, then large")
    func thumbnailPreference() {
        let all = CardImages(
            small: url("https://x/s.jpg"),
            normal: url("https://x/n.jpg"),
            large: url("https://x/l.jpg")
        )
        #expect(all.thumbnail == url("https://x/n.jpg"))

        let noNormal = CardImages(small: url("https://x/s.jpg"), large: url("https://x/l.jpg"))
        #expect(noNormal.thumbnail == url("https://x/s.jpg"))

        let onlyLarge = CardImages(large: url("https://x/l.jpg"))
        #expect(onlyLarge.thumbnail == url("https://x/l.jpg"))
    }

    @Test("listThumbnail prefers small (cheapest), then normal, then large")
    func listThumbnailPreference() {
        let all = CardImages(
            small: url("https://x/s.jpg"),
            normal: url("https://x/n.jpg"),
            large: url("https://x/l.jpg")
        )
        #expect(all.listThumbnail == url("https://x/s.jpg"))

        let noSmall = CardImages(normal: url("https://x/n.jpg"), large: url("https://x/l.jpg"))
        #expect(noSmall.listThumbnail == url("https://x/n.jpg"))

        let onlyLarge = CardImages(large: url("https://x/l.jpg"))
        #expect(onlyLarge.listThumbnail == url("https://x/l.jpg"))
    }

    @Test("hero prefers large, then png, then normal, then small")
    func heroPreference() {
        let all = CardImages(
            small: url("https://x/s.jpg"),
            normal: url("https://x/n.jpg"),
            large: url("https://x/l.jpg"),
            png: url("https://x/p.png")
        )
        #expect(all.hero == url("https://x/l.jpg"))

        let noLarge = CardImages(
            small: url("https://x/s.jpg"),
            normal: url("https://x/n.jpg"),
            png: url("https://x/p.png")
        )
        #expect(noLarge.hero == url("https://x/p.png"))
    }

    @Test("all picks are nil when no URLs are present")
    func emptyIsNil() {
        let empty = CardImages()
        #expect(empty.thumbnail == nil)
        #expect(empty.listThumbnail == nil)
        #expect(empty.hero == nil)
    }
}
