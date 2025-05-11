//
//  SearchService.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/5.
//

import Foundation
import SwiftUI

@Observable @MainActor
class SearchService {
    let fetcher: InfoFetcher = .bypassGFWForTMDbAPI
    var status: Status = .idle
    var query: String
    var movieResults: [SearchResult] = []
    var seriesResults: [SearchResult] = []
    
    init(query: String = UserDefaults.standard.string(forKey: .searchPageQuery) ?? "") {
        self.query = query
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
    
    func updateSearchResults(language: Language) async throws {
        UserDefaults.standard.set(query, forKey: .searchPageQuery)
        guard !query.isEmpty else { return }
        let currentQuery = query
        status = .fetching
        let movies = try await fetcher.searchMovies(name: currentQuery, language: language)
        let tvSeries = try await fetcher.searchTVSeries(name: currentQuery, language: language)
        let moviesPosterURLs = try await fetchPosterURLs(from: movies.map { (tmdbID: $0.id, path: $0.posterPath) })
        let seriesPosterURLs = try await fetchPosterURLs(from: tvSeries.map { (tmdbID: $0.id, path: $0.posterPath) })
        let searchMovieResults = movies.map { movie in
            SearchResult(name: movie.title,
                         overview: movie.overview,
                         posterURL: moviesPosterURLs.filter { $0.tmdbID == movie.id }.first?.url,
                         tmdbID: movie.id,
                         onAirDate: movie.releaseDate,
                         type: .movie)
        }
        let searchTVSeriesResults = tvSeries.map { series in
            SearchResult(name: series.name,
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
//            await withTaskGroup(of: Void.self) { group in
//                for series in searchTVSeriesResults {
//                    group.addTask {
//                        let seasons = try? await fetchSeasons(seriesInfo: series, language: language)
//                            .sorted {
//                                let seasonNumber1 = $0.type.seasonNumber ?? 0
//                                let seasonNumber2 = $1.type.seasonNumber ?? 0
//                                return seasonNumber1 < seasonNumber2
//                            }
//                        await MainActor.run {
//                            withAnimation {
//                                self.seriesResults[series] = seasons ?? []
//                            }
//                        }
//                    }
//                }
//            }
        }
        status = .done
        
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
    
    enum Status: Equatable {
        case idle
        case fetching
        case done
    }
}
