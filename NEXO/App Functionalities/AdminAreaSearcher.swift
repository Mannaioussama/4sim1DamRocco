//
//  AdminAreaSearcher.swift
//  NEXO
//

import SwiftUI
import Combine
import CoreLocation
import MapKit

struct AdminAreaSuggestion: Identifiable, Equatable {
    let id = UUID()
    let displayName: String
}

@MainActor
final class AdminAreaSearcher: NSObject, ObservableObject {
    @Published var suggestions: [AdminAreaSuggestion] = []
    
    private let completer: MKLocalSearchCompleter = {
        let c = MKLocalSearchCompleter()
        // Prefer addresses/regions for administrative area-like results
        c.resultTypes = [.address]
        return c
    }()
    
    private var searchTask: Task<Void, Never>?
    
    override init() {
        super.init()
        completer.delegate = self
    }
    
    func search(prefix: String) {
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            suggestions = []
            cancelOutstanding()
            return
        }
        
        // Cancel previous task and debounce a bit
        cancelOutstanding()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms debounce
            guard let self else { return }
            // Setting queryFragment triggers the completer to fetch results
            self.completer.queryFragment = trimmed
        }
    }
    
    func clear() {
        cancelOutstanding()
        suggestions = []
    }
    
    private func cancelOutstanding() {
        searchTask?.cancel()
        searchTask = nil
        completer.cancel()
    }
}

extension AdminAreaSearcher: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Hop to main actor to update @Published state
        Task { @MainActor [weak self] in
            guard let self else { return }
            let items: [AdminAreaSuggestion] = completer.results
                .map { result in
                    // Combine title and subtitle if both exist
                    let name: String
                    if result.subtitle.isEmpty {
                        name = result.title
                    } else if result.title.isEmpty {
                        name = result.subtitle
                    } else {
                        name = "\(result.title), \(result.subtitle)"
                    }
                    return AdminAreaSuggestion(displayName: name)
                }
                // Deduplicate by displayName
                .reduce(into: [String: AdminAreaSuggestion]()) { dict, s in
                    dict[s.displayName] = dict[s.displayName] ?? s
                }
                .values
                .sorted { $0.displayName < $1.displayName }
            
            self.suggestions = items
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        Task { @MainActor [weak self] in
            self?.suggestions = []
        }
    }
}
