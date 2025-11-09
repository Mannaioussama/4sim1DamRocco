//
//  MediaPicker.swift
//  NEXO
//
//  Created by ChatGPT on 11/7/2025.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

public struct PickedImage {
    public let uiImage: UIImage
    public let data: Data
    public let fileName: String
    public let mimeType: String
}

// MARK: - PHPicker (Photo Library)
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    var onPick: (PickedImage) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                parent.onCancel()
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    guard let image = object as? UIImage,
                          let data = image.jpegData(compressionQuality: 0.9) else {
                        self.parent.onCancel()
                        return
                    }
                    let fileName = (results.first?.assetIdentifier ?? UUID().uuidString) + ".jpg"
                    self.parent.onPick(PickedImage(uiImage: image, data: data, fileName: fileName, mimeType: "image/jpeg"))
                }
            }
        }
    }
}

// MARK: - Files (UIDocumentPicker restricted to images)
struct FilesImagePicker: UIViewControllerRepresentable {
    var onPick: (PickedImage) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.image, .jpeg, .png, .heic]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilesImagePicker
        init(_ parent: FilesImagePicker) { self.parent = parent }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { parent.onCancel(); return }
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else { parent.onCancel(); return }
                let fileName = url.lastPathComponent
                let mimeType: String
                if fileName.lowercased().hasSuffix(".png") { mimeType = "image/png" }
                else if fileName.lowercased().hasSuffix(".heic") { mimeType = "image/heic" }
                else { mimeType = "image/jpeg" }
                parent.onPick(PickedImage(uiImage: image, data: data, fileName: fileName, mimeType: mimeType))
            } catch {
                parent.onCancel()
            }
        }
    }
}

