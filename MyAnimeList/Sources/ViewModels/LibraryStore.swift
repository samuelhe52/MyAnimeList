//
//  LibraryStore.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import SwiftUI
import SwiftData
import DataProvider
import Combine
import Kingfisher
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "LibraryStore")

@Observable @MainActor
class LibraryStore {
    @ObservationIgnored private let dataProvider: DataProvider
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    private(set) var library: [AnimeEntry]
    @ObservationIgnored private var infoFetcher: InfoFetcher
    var language: Language = .current
    
    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        self.library = []
        self.infoFetcher = .init()
        setupUpdateLibrary()
        setupTMDbAPIConfigurationChangeMonitor()
        try? refreshLibrary()
    }
    
    func refreshLibrary(sortedBy sortDescriptor: SortDescriptor<AnimeEntry> = .init(\.dateSaved)) throws {
        logger.debug("Refreshing library...")
        let descriptor = FetchDescriptor<AnimeEntry>(
            predicate: #Predicate { $0.onDisplay },
            sortBy: [sortDescriptor]
        )
        let entries = try dataProvider.sharedModelContainer.mainContext.fetch(descriptor)
        withAnimation {
            library = entries
        }
    }
    
    func setupUpdateLibrary() {
        NotificationCenter.default
            .publisher(for: ModelContext.didSave)
            .sink { [weak self] _ in
                do {
                    try self?.refreshLibrary()
                } catch {
                    logger.error("Error refreshing library: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    func setupTMDbAPIConfigurationChangeMonitor() {
        NotificationCenter.default
            .publisher(for: .TMDbAPIConfigurationDidChange)
            .sink { [weak self] _ in
                self?.infoFetcher = .init()
            }
            .store(in: &cancellables)
    }
    
    private func createNewEntry(tmdbID id: Int, type: AnimeType) async throws {
        logger.debug("Creating new entry with id: \(id), type: \(type)...")
        // No duplicate entries
        guard library.map(\.tmdbID).contains(id) == false else {
            library[id].onDisplay = true
            logger.warning("Entry with id \(id) already exists. Setting `onDisplay` to `true` and Returning...")
            return
        }
        let info = try await infoFetcher.fetchInfoFromTMDB(entryType: type,
                                                           tmdbID: id,
                                                           language: language)
        let entry = AnimeEntry(fromInfo: info)
        if let parentSeriesID = entry.parentSeriesID,
           let parentSeriesEntry = library.first(where: { $0.tmdbID == parentSeriesID }) {
            entry.parentSeriesEntry = parentSeriesEntry
        }
        try dataProvider.dataHandler.newEntry(entry)
    }
    
    /// Creates a new `AnimeEntry` from a TMDB ID and adds it to the library.
    /// It does nothing if an entry with the same TMDB ID already exist.
    ///
    /// - Returns:`true` if no error occurred; otherwise `false`.
    func newEntry(tmdbID id: Int, type: AnimeType) async -> Bool {
        do {
            try await createNewEntry(tmdbID: id, type: type)
            return true
        } catch {
            logger.error("Error creating new entry: \(error)")
            ToastCenter.global.completionState = .failed(error.localizedDescription)
            return false
        }
    }
    
    /// Creates new `AnimeEntry` instances from search results and adds them to the library.
    /// - Returns: `true` if no error occurred; otherwise `false`.
    func newEntryFromSearchResults<Sources: Collection<SearchResult>>(_ results: Sources) async -> Bool {
        do {
            for result in results {
                try await createNewEntry(tmdbID: result.tmdbID, type: result.type)
            }
            return true
        } catch {
            logger.error("Error creating new entries from search results: \(error)")
            ToastCenter.global.completionState = .failed(error.localizedDescription)
            return false
        }
    }
    
    /// Creates new `AnimeEntry` instances from a `BasicInfo` and adds it to the library.
    func newEntryFromBasicInfo(_ info: BasicInfo) {
        do {
            try dataProvider.dataHandler.newEntry(.init(fromInfo: info))
        } catch {
            logger.error("Error creating new entry from BasicInfo: \(error)")
        }
    }
    
    /// Fetches the latest infos from tmdb for all entries and update the entries.
    func refreshInfos() {
        Task {
            defer { ToastCenter.global.refreshingInfos = false }
            ToastCenter.global.refreshingInfos = true
            var fetchedInfos: [(PersistentIdentifier, BasicInfo)] = []

            do {
                try await withThrowingTaskGroup(of: (PersistentIdentifier, BasicInfo).self) { group in
                    for entry in library {
                        let type = entry.type
                        let tmdbID = entry.tmdbID
                        let entryID = entry.id
                        let language = language
                        let usingCustomPoster = entry.usingCustomPoster
                        let originalPosterURL = entry.posterURL
                        group.addTask {
                            var info = try await self.infoFetcher.fetchInfoFromTMDB(entryType: type,
                                                                                    tmdbID: tmdbID,
                                                                                    language: language)
                            if usingCustomPoster {
                                info.posterURL = originalPosterURL
                            }
                            return (entryID, info)
                        }
                    }

                    for try await result in group {
                        fetchedInfos.append(result)
                    }
                }

                for (id, info) in fetchedInfos {
                    if let entry = library[id] {
                        entry.update(from: info)
                        if let parentSeriesID = entry.parentSeriesID {
                            if let parentSeriesEntry = library[parentSeriesID] {
                                entry.parentSeriesEntry = parentSeriesEntry
                            } else {
                                let parentSeriesInfo = try await infoFetcher.tvSeriesInfo(tmdbID: parentSeriesID, language: language)
                                let parentSeriesEntry = AnimeEntry(fromInfo: parentSeriesInfo)
                                parentSeriesEntry.onDisplay = false
                                entry.parentSeriesEntry = parentSeriesEntry
                            }
                        }
                    }
                }
            } catch {
                logger.error("Error refreshing infos: \(error)")
                ToastCenter.global.completionState = .failed(error.localizedDescription)
                return
            }
            prefetchAllImages()
        }
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
            logger.info("Prefetched images: \(message)")
        })
        ToastCenter.global.prefetchingImages = true
        prefetcher.start()
    }
    
    func deleteEntry(_ entry: AnimeEntry) {
        do {
            try dataProvider.dataHandler.deleteEntry(entry)
        } catch {
            logger.error("Failed to delete entry: \(error)")
            ToastCenter.global.completionState = .failed(error.localizedDescription)
        }
    }
    
    func clearLibrary() {
        do {
            try dataProvider.dataHandler.deleteAllEntries()
        } catch {
            logger.error("Error clearing library: \(error)")
            ToastCenter.global.completionState = .failed(error.localizedDescription)
        }
    }
}

// This is where we place debug-specific code.
extension LibraryStore {
    /// Mock delete, doesn't really touch anything in the persisted data model. Restores after 1.5 seconds.
    func mockDeleteEntry(_ entry: AnimeEntry) {
        if let index = library.firstIndex(where: { $0.id == entry.id }) {
            library.remove(at: index)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.library.insert(entry, at: index)
            }
        }
    }
}
