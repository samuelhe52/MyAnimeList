//
//  SearchService.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/5.
//

import Foundation
import SwiftUI
import DataProvider
import Collections
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "SearchService")

struct SearchResult: Hashable {
    var tmdbID: Int
    var type: AnimeType
}

@Observable @MainActor
class SearchService {
    let fetcher: InfoFetcher = .init()
    private(set) var status: Status = .loading
    var query: String
    private(set) var movieResults: [BasicInfo] = []
    private(set) var seriesResults: [BasicInfo] = []
    
    private var resultsToSubmit: OrderedSet<SearchResult> = []
    var processResults: (OrderedSet<SearchResult>) -> Void
    
    init(query: String = UserDefaults.standard.string(forKey: .searchPageQuery) ?? "",
         processResults: @escaping (OrderedSet<SearchResult>) -> Void) {
        self.query = query
        self.processResults = processResults
    }
    
    /// Submit the final results.
    func submit() { processResults(OrderedSet(resultsToSubmit.reversed())) }
    /// The count of all results pending submission.
    var registeredCount: Int { resultsToSubmit.count }
    /// Appends a result to the submission queue.
    func register(_ result: SearchResult) { resultsToSubmit.insert(result, at: 0) }
    /// Creates a result from a `BasicInfo` to the submission queue.
    func register(info: BasicInfo) { resultsToSubmit.insert(.init(tmdbID: info.tmdbID, type: info.type), at: 0) }
    /// Removes a result from the submission queue if it is present.
    func unregister(_ result: SearchResult) { resultsToSubmit.remove(result) }
    /// Removes a result corresponding to the provided `BasicInfo` from the submission queue if it is present.
    func unregister(info: BasicInfo) { resultsToSubmit.remove(.init(tmdbID: info.tmdbID, type: info.type)) }
    /// Removes all series/movie results
    func clearAll() {
        resultsToSubmit.removeAll()
    }
    
    private func fetchPosterURLs(from items: [(tmdbID: Int, path: URL?)]) async throws -> [(tmdbID: Int, url: URL?)] {
        return try await withThrowingTaskGroup(of: (tmdbID: Int, url: URL?).self) { group in
            for item in items {
                group.addTask {
                    let url = try await self.fetcher
                        .tmdbClient
                        .imagesConfiguration
                        .posterURL(for: item.path, idealWidth: 200)
                    return (tmdbID: item.tmdbID, url: url)
                }
            }
            
            var results: [(tmdbID: Int, url: URL?)] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    func updateResults(language: Language) {
        UserDefaults.standard.set(query, forKey: .searchPageQuery)
        guard !query.isEmpty else { return }
        Task {
            let currentQuery = query
            status = .loading
            do {
                let movies = try await fetcher.searchMovies(name: currentQuery, language: language)
                let tvSeries = try await fetcher.searchTVSeries(name: currentQuery, language: language)
                let moviesPosterURLs = try await fetchPosterURLs(from: movies.map { (tmdbID: $0.id, path: $0.posterPath) })
                let seriesPosterURLs = try await fetchPosterURLs(from: tvSeries.map { (tmdbID: $0.id, path: $0.posterPath) })
                let searchMovieResults = movies.map { movie in
                    BasicInfo(name: movie.title,
                                 overview: movie.overview,
                                 posterURL: moviesPosterURLs.filter { $0.tmdbID == movie.id }.first?.url,
                                 tmdbID: movie.id,
                                 onAirDate: movie.releaseDate,
                                 type: .movie)
                }
                let searchTVSeriesResults = tvSeries.map { series in
                    BasicInfo(name: series.name,
                                 overview: series.overview,
                                 posterURL: seriesPosterURLs.filter { $0.tmdbID == series.id }.first?.url,
                                 tmdbID: series.id,
                                 onAirDate: series.firstAirDate,
                                 type: .series)
                }
            
                if currentQuery == query {
                    withAnimation {
                        movieResults = searchMovieResults
                        seriesResults = searchTVSeriesResults
                    }
                }
            } catch {
                logger.error("Error in fetching search results: \(error)")
                status = .error(error)
            }
            status = .loaded
        }
        
        func fetchSeasons(seriesInfo info: BasicInfo, language: Language) async throws -> [BasicInfo] {
            let fetcher = InfoFetcher()
            let series = try await fetcher.tvSeries(info.tmdbID, language: language)
            guard let seasons = series.seasons else { return [] }
            let infos = try await withThrowingTaskGroup(of: BasicInfo.self) { group in
                var results: [BasicInfo] = []
                for season in seasons {
                    group.addTask {
                        return try await fetcher.tvSeasonInfo(seasonNumber: season.seasonNumber,
                                                              parentSeriesID: info.tmdbID,
                                                              language: language)
                    }
                }
                for try await result in group {
                    results.append(result)
                }
                return results
            }
            return infos
        }
    }
    
    enum Status {
        case loading
        case loaded
        case error(Error)
    }
}

extension SearchService.Status: Equatable {
    static func == (lhs: SearchService.Status, rhs: SearchService.Status) -> Bool {
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
