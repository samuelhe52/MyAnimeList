//
//  LibraryStore.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Combine
import DataProvider
import Foundation
import Kingfisher
import SwiftData
import SwiftUI
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "LibraryStore")

@Observable @MainActor
class LibraryStore {
    @ObservationIgnored private let dataProvider: DataProvider
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored let backupManager: BackupManager

    var libraryOnDisplay: [AnimeEntry] {
        filterAndSort(library)
    }
    private(set) var library: [AnimeEntry]
    @ObservationIgnored private var infoFetcher: InfoFetcher
    var language: Language = .current
    var filters: Set<AnimeFilter> = []

    var sortStrategy: AnimeSortStrategy = .dateStarted {
        willSet {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: .librarySortStrategy)
            logger.debug("Updated sort strategy to \(newValue.rawValue)")
        }
    }
    var sortReversed: Bool = false

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        self.backupManager = BackupManager(dataProvider: dataProvider)
        self.library = []
        self.infoFetcher = .init()
        if let sortStrategyRawValue = UserDefaults.standard.string(forKey: .librarySortStrategy),
            let strategy = AnimeSortStrategy(rawValue: sortStrategyRawValue)
        {
            self.sortStrategy = strategy
        }
        setupUpdateLibrary()
        setupTMDbAPIConfigurationChangeMonitor()
        try? refreshLibrary()
    }

    func refreshLibrary() throws {
        logger.debug("[\(Date().debugDescription)] Refreshing library...")
        let entries = try dataProvider.getAllModels(ofType: AnimeEntry.self, predicate: #Predicate { $0.onDisplay })
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
            .publisher(for: .tmdbAPIConfigurationDidChange)
            .sink { [weak self] _ in
                self?.infoFetcher = .init()
            }
            .store(in: &cancellables)
    }

    private func createNewEntry(tmdbID id: Int, type: AnimeType) async throws {
        // No duplicate entries
        guard library.map(\.tmdbID).contains(id) == false else {
            library.entryWithTMDbID(id)?.onDisplay = true
            logger.warning(
                "Entry with id \(id) already exists. Setting `onDisplay` to `true` and returning..."
            )
            return
        }
        logger.debug("Creating new entry with id: \(id), type: \(type)...")
        let info = try await infoFetcher.fetchInfoFromTMDB(
            entryType: type,
            tmdbID: id,
            language: language)
        let entry = AnimeEntry(fromInfo: info)
        if let parentSeriesID = entry.parentSeriesID {
            if let parentSeriesEntry = library.first(where: { $0.tmdbID == parentSeriesID }) {
                entry.parentSeriesEntry = parentSeriesEntry
            } else {
                let parentSeriesEntry =
                    try await AnimeEntry
                    .generateParentSeriesEntryForSeason(
                        parentSeriesID: parentSeriesID,
                        fetcher: infoFetcher,
                        infoLanguage: language)
                entry.parentSeriesEntry = parentSeriesEntry
            }
        }
        try dataProvider.dataHandler.newEntry(entry)
    }

    /// Creates a new `AnimeEntry` from a TMDB ID and adds it to the library.
    ///
    /// Does nothing if an entry with the same TMDB ID already exist.
    ///
    /// - Parameters:
    ///   - id: The TMDB ID of the anime to add.
    ///   - type: The type of the anime (e.g., `.movie`).
    ///
    /// - Returns: `true` if no error occurred; otherwise `false`.
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
    func newEntryFromSearchResults<Sources: Collection<SearchResult>>(_ results: Sources) async
        -> Bool
    {
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
                try await withThrowingTaskGroup(
                    of: (PersistentIdentifier, BasicInfo).self
                ) { group in
                    for entry in library {
                        let original = entry.basicInfo
                        let entryID = entry.id
                        let language = self.language
                        let usingCustomPoster = entry.usingCustomPoster
                        group.addTask {
                            var info = try await self.infoFetcher.fetchInfoFromTMDB(
                                entryType: original.type,
                                tmdbID: original.tmdbID,
                                language: language)
                            if usingCustomPoster {
                                // Preserve the original poster URL if using a custom poster
                                info.posterURL = original.posterURL
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
                        try await resolveParentSeriesEntry(for: entry)
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

    func resolveParentSeriesEntry(for entry: AnimeEntry) async throws {
        if let parentSeriesID = entry.parentSeriesID {
            if let parentSeriesEntry = library.entryWithTMDbID(parentSeriesID) {
                entry.parentSeriesEntry = parentSeriesEntry
            } else {
                if let parentSeriesID = entry.parentSeriesID {
                    let parentSeriesEntry =
                        try await AnimeEntry
                        .generateParentSeriesEntryForSeason(
                            parentSeriesID: parentSeriesID,
                            fetcher: infoFetcher,
                            infoLanguage: language)
                    entry.parentSeriesEntry = parentSeriesEntry
                }
            }
        }
    }

    func prefetchAllImages() {
        let urls = library.compactMap { $0.posterURL }
        let prefetcher = ImagePrefetcher(
            urls: urls,
            completionHandler: { skipped, failed, completed in
                ToastCenter.global.prefetchingImages = false
                var state: ToastCenter.CompletedWithMessage.State = .completed
                let messageResourceString =
                    "Fetched: \(skipped.count + completed.count), failed: \(failed.count)"
                let messageResource = LocalizedStringResource(
                    "Fetched: \(skipped.count + completed.count), failed: \(failed.count)")
                if failed.isEmpty {
                    state = .completed
                } else if completed.isEmpty && skipped.isEmpty {
                    state = .failed
                } else {
                    state = .partialComplete
                }
                ToastCenter.global.completionState = .init(
                    state: state,
                    messageResource: messageResource)
                logger.info("Prefetched images: \(messageResourceString)")
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

    func filterAndSort(_ entries: [AnimeEntry]) -> [AnimeEntry] {
        let sorted: [AnimeEntry]
        if !sortReversed {
            sorted =
                entries
                .sorted(by: sortStrategy.compare)
        } else {
            sorted =
                entries
                .sorted(by: sortStrategy.compare)
                .reversed()
        }
        guard filters.isEmpty else {
            return sorted.filter { entry in
                filters.contains { filter in
                    filter.evaluate(entry)
                }
            }
        }
        return sorted
    }

    struct AnimeFilter: Sendable, CaseIterable, Equatable, Hashable {
        static let favorited = AnimeFilter(id: "Favorited", name: "Favorited") { $0.favorite }
        static let watched = AnimeFilter(id: "Watched", name: "Watched") {
            $0.watchStatus == WatchedStatus.watched
        }
        static let planToWatch = AnimeFilter(id: "Plan to Watch", name: "Plan to Watch") {
            $0.watchStatus == .planToWatch
        }
        static let watching = AnimeFilter(id: "Watching", name: "Watching") {
            $0.watchStatus == .watching
        }

        private init(
            id: String, name: LocalizedStringResource,
            evaluate: @escaping @Sendable (AnimeEntry) -> Bool
        ) {
            self.id = id
            self.name = name
            self.evaluate = evaluate
        }

        let id: String
        let name: LocalizedStringResource
        let evaluate: @Sendable (AnimeEntry) -> Bool

        static var allCases: [LibraryStore.AnimeFilter] {
            [.favorited, .watched, .planToWatch, .watching]
        }

        static func == (lhs: LibraryStore.AnimeFilter, rhs: LibraryStore.AnimeFilter) -> Bool {
            lhs.name == rhs.name
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    enum AnimeSortStrategy: String,
        CaseIterable,
        CustomLocalizedStringResourceConvertible,
        Codable
    {
        case dateSaved, dateStarted, dateFinished, dateOnAir

        func compare(_ lhs: AnimeEntry, _ rhs: AnimeEntry) -> Bool {
            switch self {
            case .dateSaved:
                return lhs.dateSaved < rhs.dateSaved
            case .dateStarted:
                return lhs.dateStarted ?? .distantFuture < rhs.dateStarted ?? .distantFuture
            case .dateFinished:
                return lhs.dateFinished ?? .distantFuture < rhs.dateFinished ?? .distantFuture
            case .dateOnAir:
                return lhs.onAirDate ?? .distantFuture < rhs.onAirDate ?? .distantFuture
            }
        }

        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .dateFinished: "Date Finished"
            case .dateSaved: "Date Saved"
            case .dateStarted: "Date Started"
            case .dateOnAir: "Date On Air"
            }
        }
    }
}

// This is where we place debug-specific code.
extension LibraryStore {
    /// Mock delete, doesn't really touch anything in the persisted data model.
    ///
    /// Restores after 1.5 seconds.
    func mockDeleteEntry(_ entry: AnimeEntry) {
        if let index = library.firstIndex(where: { $0.id == entry.id }) {
            library.remove(at: index)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.library.insert(entry, at: index)
            }
        }
    }
}
