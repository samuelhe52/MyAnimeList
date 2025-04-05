//
//  LibraryStore.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import SwiftUI

@Observable
class LibraryStore {
    var library: [AnimeEntry] = []
    private var infoFetcher: InfoFetcher = .init()
    
    @MainActor
    func changePreferredLanguage(_ language: Language) {
        Task { await infoFetcher.changeLanguage(language) }
    }
    
    @MainActor
    func newEntryFromSearchResult(result: SearchResult) {
        Task {
            let info = try await infoFetcher.fetchInfoFromTMDB(entryType: result.typeMetadata, id: result.id)
            library.append(AnimeEntry(fromInfo: info))
        }
    }
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    func updateInfos() async throws {
        for index in library.indices {
            let info = try await infoFetcher.fetchInfoFromTMDB(entryType: library[index].entryType, id: library[index].id)
            library[index].update(fromInfo: info)
        }
    }
    
    func updateInfo(entryID id: AnimeEntry.ID) async throws {
        if let entry = library[id] {
            let info = try await infoFetcher.fetchInfoFromTMDB(entryType: entry.entryType, id: entry.id)
            library[id]?.update(fromInfo: info)
        }
    }
}

extension Array where Element == AnimeEntry {
    subscript(id: AnimeEntry.ID) -> AnimeEntry? {
        get { first { $0.id == id } }
        set {
            guard let index = firstIndex(where: { $0.id == id }),
                  let newValue else { return }
            self[index] = newValue
        }
    }
}
