//
//  LibraryStore.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@Observable @MainActor
class LibraryStore {
    private let dataProvider: DataProvider
    private var cancellables = Set<AnyCancellable>()

    private(set) var library: [AnimeEntry] = []
    private let infoFetcher: InfoFetcher = .bypassGFWForTMDbAPI
    var language: Language = .japanese
    
    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        setupUpdateData()
        try? fetchAndUpdate()
    }
    
    func fetchAndUpdate() throws {
        let descriptor = FetchDescriptor<AnimeEntry>(sortBy: [SortDescriptor(\.dateSaved)])
        let entries = try dataProvider.sharedModelContainer.mainContext.fetch(descriptor)
        library = entries
    }
    
    func setupUpdateData() {
        NotificationCenter.default
            .publisher(for: ModelContext.didSave)
            .sink { [weak self] _ in
                do {
                    try self?.fetchAndUpdate()
                } catch {
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    
    /// Creates a new `AnimeEntry` from a `SearchResult` and adds it to the library.
    /// It does nothing if an entry with the same TMDB ID already exist.
    func newEntryFromSearchResult(result: SearchResult) async throws {
        guard library.map({ $0.tmdbID }).contains(result.tmdbID) == false else { return }
        let info = try await infoFetcher.fetchInfoFromTMDB(entryType: result.typeMetadata,
                                                           tmdbID: result.tmdbID,
                                                           language: language)
        let entry = AnimeEntry(fromInfo: info)
        try await dataProvider.dataHandler.newEntry(entry)
    }
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    func refreshInfos() async throws {
        for index in library.indices {
            let info = try await infoFetcher.fetchInfoFromTMDB(entryType: library[index].entryType,
                                                               tmdbID: library[index].tmdbID,
                                                               language: language)
            try await dataProvider.dataHandler.updateEntry(id: library[index].id, info: info)
        }
    }
    
    func deleteEntry(id: PersistentIdentifier) async throws {
        try await dataProvider.dataHandler.deleteEntry(id: id)
    }
    
    func clearLibrary() async throws {
        try await dataProvider.dataHandler.deleteAllEntries()
    }
}
