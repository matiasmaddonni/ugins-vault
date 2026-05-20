//
//  AvatarStorage.swift
//  UginsVault — Data layer / Local
//
//  Saves + loads the user's profile avatar to/from the app's
//  Documents directory. Filenames are caller-supplied (matches the
//  `UserProfile.avatarFilename` field) so the storage stays a thin
//  file-IO layer with no model awareness.
//

import Foundation
import UIKit

@MainActor
public protocol AvatarStorage: AnyObject, Sendable {

    /// Writes JPEG data to Documents and returns the file name (no path).
    func saveImage(_ image: UIImage) throws -> String

    /// Loads the image at the given filename. Returns `nil` if the
    /// file is missing or unreadable.
    func loadImage(filename: String) -> UIImage?

    /// Best-effort delete. No-op when the file doesn't exist.
    func deleteImage(filename: String)
}

@MainActor
public final class FileAvatarStorage: AvatarStorage {

    private let fileManager: FileManager
    private let jpegQuality: CGFloat

    public init(fileManager: FileManager = .default, jpegQuality: CGFloat = 0.85) {
        self.fileManager = fileManager
        self.jpegQuality = jpegQuality
    }

    public func saveImage(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: jpegQuality) else {
            throw AvatarStorageError.encodingFailed
        }
        let filename = "uv-avatar-\(UUID().uuidString).jpg"
        let url = documentsDirectory().appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return filename
    }

    public func loadImage(filename: String) -> UIImage? {
        let url = documentsDirectory().appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    public func deleteImage(filename: String) {
        let url = documentsDirectory().appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }

    private func documentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }
}

public enum AvatarStorageError: Error, LocalizedError {
    case encodingFailed
    public var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Couldn't encode the avatar image."
        }
    }
}
