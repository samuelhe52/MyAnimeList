//
//  SearchPage.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/30.
//

import SwiftUI
import Kingfisher

typealias SearchResult = BasicInfo

struct SearchPage: View {
    @Bindable var service: SearchService
    @AppStorage("language") private var language: Language = .english
    var processResult: (SearchResult) -> Void
    
    var body: some View {
        List {
            Picker("Language", selection: $language) {
                ForEach(Language.allCases, id: \.rawValue) {
                    Text($0.description).tag($0)
                }
            }
            if service.status == .done {
                results
            }
        }
        .searchable(text: $service.query, prompt: "Search TV animation or movies...")
        .onSubmit(of: .search) { updateResults() }
        .listStyle(.inset)
        .onAppear { updateResults() }
        .onChange(of: language) { updateResults() }
        .animation(.default, value: service.movieResults)
        .animation(.default, value: service.seriesResults)
        .animation(.default, value: service.status)
    }
    
    @ViewBuilder
    private var results: some View {
        if !service.seriesResults.isEmpty {
            Section("Series") {
                ForEach(service.seriesResults.prefix(8), id: \.tmdbID) { series in
                    ResultItem(result: series)
                        .onTapGesture { processResult(series) }
                }
            }
        }
        if !service.movieResults.isEmpty {
            Section("Movies") {
                ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                    ResultItem(result: movie)
                        .onTapGesture { processResult(movie) }
                }
            }
        }
    }
    
    private func updateResults() {
        Task { try await service.updateSearchResults(language: language) }
    }
}

struct ResultItem: View {
    let result: SearchResult
    
    var body: some View {
        HStack {
            poster(url: result.posterURL)
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 6))
                .frame(width: 60, height: 90)
            VStack(alignment: .leading) {
                Text(result.name)
                    .bold()
                    .lineLimit(1)
                if let date = result.onAirDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .padding(.bottom, 1)
                }
                Text(result.overview ?? "No overview available")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .lineLimit(3)
            }
        }
    }
    
    @ViewBuilder
    private func poster(url: URL?) -> some View {
        if let url {
            KFImage(url)
                .resizable()
                .fade(duration: 0.3)
                .placeholder {
                    ProgressView()
                }
                .cacheOriginalImage()
                .diskCacheExpiration(.days(1))
                .cancelOnDisappear(true)
        } else {
            Image("missing_image_resource")
                .resizable()
        }
    }
}

@Observable @MainActor
class SearchService {
    let fetcher: InfoFetcher = .bypassGFWForTMDbAPI
    var status: Status = .idle
    var query: String {
        didSet {
            UserDefaults.standard.set(query, forKey: "SearchPageQuery")
        }
    }
    var movieResults: [SearchResult] = []
    var seriesResults: [SearchResult] = []
    
    init(query: String = UserDefaults.standard.string(forKey: "SearchPageQuery") ?? "") {
        self.query = query
    }
    
    func updateSearchResults(language: Language) async throws {
        guard !query.isEmpty else { return }
        let currentQuery = query
        status = .fetching
        let movies = try await fetcher.searchMovies(name: currentQuery, language: language)
        let tvSeries = try await fetcher.searchTVSeries(name: currentQuery, language: language)
        
        var searchMovieResults = movies.map { movie in
            SearchResult(name: movie.title,
                         overview: movie.overview,
                         posterPath: movie.posterPath,
                         tmdbID: movie.id,
                         onAirDate: movie.releaseDate,
                         typeMetadata: .movie)
        }
        var searchTVSeriesResults = tvSeries.map { series in
            SearchResult(name: series.name,
                         overview: series.overview,
                         posterPath: series.posterPath,
                         tmdbID: series.id,
                         onAirDate: series.firstAirDate,
                         typeMetadata: .tvSeries)
        }
        
        // The poster displayed here is small and we use smaller sizes
        // to reduce network overhead.
        try await searchMovieResults.updatePosterURLs(width: 200)
        try await searchTVSeriesResults.updatePosterURLs(width: 200)

        if currentQuery == query {
            movieResults = searchMovieResults
            seriesResults = searchTVSeriesResults
        }
        status = .done
    }
    
    enum Status: Equatable {
        case idle
        case fetching
        case done
    }
}

#Preview {
    @Previewable @State var service = SearchService(query: "K-on!")
    
    NavigationStack {
        SearchPage(service: service) { _ in }
    }
}
