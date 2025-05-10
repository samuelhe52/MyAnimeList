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
import Kingfisher

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
        withAnimation {
            library = entries
        }
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
    
    /// Creates a new `AnimeEntry` from a `BasicInfo` and adds it to the library.
    /// It does nothing if an entry with the same TMDB ID already exist.
    func newEntryFromInfo(info: BasicInfo) async throws {
        // No duplicatye entries
        guard library.map({ $0.tmdbID }).contains(info.tmdbID) == false else { return }
        let info = try await infoFetcher.fetchInfoFromTMDB(entryType: info.type,
                                                           tmdbID: info.tmdbID,
                                                           language: language)
        let entry = AnimeEntry(fromInfo: info)
        try await dataProvider.dataHandler.newEntry(entry)
    }
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    func refreshInfos() async throws {
        ToastCenter.global.refreshingInfos = true
        for index in library.indices {
            let info = try await infoFetcher.fetchInfoFromTMDB(entryType: library[index].type,
                                                               tmdbID: library[index].tmdbID,
                                                               language: language)
            try await dataProvider.dataHandler.updateEntry(id: library[index].id, info: info)
        }
        ToastCenter.global.refreshingInfos = false
        prefetchAllImages()
    }
    
    func prefetchAllImages() {
        let urls = library.compactMap { $0.posterURL }
        let prefetcher = ImagePrefetcher(urls: urls, completionHandler: { skipped, failed, completed  in
            ToastCenter.global.prefetchingImages = false
            var state: ToastCenter.CompletedWithMessage.State = .completed
            let message = "Fetched: \(skipped.count + completed.count), failed: \(failed.count)"
            if failed.isEmpty {
                state = .completed
            } else if completed.isEmpty && skipped.isEmpty {
                state = .failed
            } else { state = .partialComplete }
            ToastCenter.global.completionState = .init(state: state, message: message)
        })
        ToastCenter.global.prefetchingImages = true
        prefetcher.start()
    }
    
    func deleteEntry(withID id: PersistentIdentifier) async throws {
        try await dataProvider.dataHandler.deleteEntry(id: id)
    }
    
    func clearLibrary() async throws {
        try await dataProvider.dataHandler.deleteAllEntries()
    }
}

// This is where we place debug-specific code.
extension LibraryStore {
    /// Mock delete, doesn't really touch anything in the persisted data model. Restores after 1.5 seconds.
    func mockDeleteEntry(withID id: PersistentIdentifier) {
        if let index = library.firstIndex(where: { $0.id == id }) {
            let entry = library[index]
            library.remove(at: index)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.library.insert(entry, at: index)
            }
        }
    }
}
