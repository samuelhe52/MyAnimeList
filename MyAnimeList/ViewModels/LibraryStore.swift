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

@Observable
class LibraryStore {
    var dataProvider: DataProvider
    private var cancellables = Set<AnyCancellable>()

    @MainActor
    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        setupUpdateData()
        try? fetchData()
    }
    
    private(set) var library: [AnimeEntry] = []
    private var infoFetcher: InfoFetcher = .init()
    
    @MainActor
    func fetchData() throws {
        let descriptor = FetchDescriptor<AnimeEntry>(sortBy: [SortDescriptor(\.dateSaved)])
        let entries = try dataProvider.sharedModelContainer.mainContext.fetch(descriptor)
        library = entries
    }
    
    @MainActor
    func setupUpdateData() {
        NotificationCenter.default
            .publisher(for: ModelContext.didSave)
            .sink { [weak self] _ in
                do {
                    try self?.fetchData()
                } catch {
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func changePreferredLanguage(_ language: Language) {
        Task { await infoFetcher.changeLanguage(language) }
    }
    
    @MainActor
    func newEntryFromSearchResult(result: SearchResult) {
        Task {
            let info = try await infoFetcher.fetchInfoFromTMDB(entryType: result.typeMetadata, tmdbID: result.tmdbID)
            let entry = AnimeEntry(fromInfo: info)
            try await dataProvider.dataHandler.newEntry(entry)
        }
    }
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    func refreshInfos() async throws {
        for index in library.indices {
            let info = try await infoFetcher.fetchInfoFromTMDB(entryType: library[index].entryType, tmdbID: library[index].tmdbID)
            try await dataProvider.dataHandler.updateEntry(id: library[index].id, info: info)
        }
    }
    
    @MainActor
    func deleteEntry(id: PersistentIdentifier) {
        Task { try await dataProvider.dataHandler.deleteEntry(id: id) }
    }
    
    @MainActor
    func clearLibrary() {
        Task { try await dataProvider.dataHandler.deleteAllEntries() }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
