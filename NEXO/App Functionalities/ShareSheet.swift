import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("[ShareSheet] activityItems:", activityItems)
        if let firstText = activityItems
            .compactMap({ $0 as? String })
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty }) {
            UIPasteboard.general.string = firstText
            print("[ShareSheet] Copied to pasteboard:\n\(firstText)")
        }
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
