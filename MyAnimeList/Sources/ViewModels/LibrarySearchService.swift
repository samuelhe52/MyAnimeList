//
//  LibrarySearchService.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/10/5.
//


import Foundation
import SwiftUI
import DataProvider
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "LibrarySearchService")

@Observable @MainActor
class LibrarySearchService {
    private let dataProvider = DataProvider.default
    var query: String
    private var entries: [AnimeEntry] = []
    private(set) var jumpToEntryInLibrary: (Int) -> Void

    private(set) var results: [AnimeEntry] = []
    private(set) var status: Status = .loaded

    init(query: String = UserDefaults.standard.string(forKey: .searchPageQuery) ?? "",
         jumpToEntryInLibrary: @escaping (Int) -> Void = { _ in }) {
        self.query = query
        self.jumpToEntryInLibrary = jumpToEntryInLibrary
    }
    
    enum Status: Equatable {
        case loading
        case loaded
        case error(Error)
        
        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.loaded, .loaded):
                return true
            case (.error(let e1), .error(let e2)):
                return (e1 as NSError).domain == (e2 as NSError).domain &&
                       (e1 as NSError).code == (e2 as NSError).code
            default:
                return false
            }
        }
    }

    func updateResults() {
        status = .loading
        UserDefaults.standard.set(query, forKey: .searchPageQuery)
        loadModels()
        if query.isEmpty {
            results = []
        } else {
            let lowercasedQuery = query.lowercased()
            withAnimation {
                results = entries
                    .filter { $0.displayName.lowercased().contains(lowercasedQuery) }
            }
        }
        status = .loaded
    }

    private func loadModels() {
        do {
            entries = try dataProvider.getAllModels(ofType: AnimeEntry.self)
        } catch {
            logger.error("Error loading AnimeEntry models: \(error)")
            status = .error(error)
        }
    }
}
