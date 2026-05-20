//
//  AvatarPicker.swift
//  UginsVault — Presentation: Design System
//
//  Combined source picker for the profile avatar — PhotosPicker for
//  gallery (no permission prompt needed in SwiftUI's variant) +
//  UIImagePickerController for camera. Bottom-sheet picker offers
//  both options + a "Remove photo" action.
//

import SwiftUI
import PhotosUI
import UIKit

public struct AvatarPicker: View {

    @Binding public var pickerItem: PhotosPickerItem?
    public let allowCamera: Bool
    public let allowRemove: Bool
    public let onCameraTap: () -> Void
    public let onRemove: () -> Void

    public init(
        pickerItem: Binding<PhotosPickerItem?>,
        allowCamera: Bool = true,
        allowRemove: Bool = true,
        onCameraTap: @escaping () -> Void = {},
        onRemove: @escaping () -> Void = {}
    ) {
        self._pickerItem = pickerItem
        self.allowCamera = allowCamera
        self.allowRemove = allowRemove
        self.onCameraTap = onCameraTap
        self.onRemove = onRemove
    }

    public var body: some View {
        VStack(spacing: Spacing.sm) {
            PhotosPicker(
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Choose from library", systemImage: "photo.on.rectangle")
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.rowHorizontal)
                    .padding(.vertical, Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .fill(Color.uv.panel)
                    )
            }

            if allowCamera {
                Button(action: onCameraTap) {
                    Label("Take photo", systemImage: "camera")
                        .font(.uv.body(14, weight: .semibold))
                        .foregroundStyle(Color.uv.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.rowHorizontal)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: UVRadius.md)
                                .fill(Color.uv.panel)
                        )
                }
                .buttonStyle(.plain)
            }

            if allowRemove {
                Button(role: .destructive, action: onRemove) {
                    Label("Remove photo", systemImage: "trash")
                        .font(.uv.body(14, weight: .semibold))
                        .foregroundStyle(Color.uv.down)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.rowHorizontal)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: UVRadius.md)
                                .fill(Color.uv.panel)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - UIImagePickerController bridge for camera capture

public struct CameraCaptureSheet: UIViewControllerRepresentable {

    public let onCapture: (UIImage) -> Void
    public let onCancel: () -> Void

    public init(
        onCapture: @escaping (UIImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onCapture = onCapture
        self.onCancel = onCancel
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.allowsEditing = true
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel: () -> Void
        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            if let image { onCapture(image) } else { onCancel() }
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
