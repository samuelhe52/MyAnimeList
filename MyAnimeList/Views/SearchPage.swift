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
    @State var service: SearchService = .init()
    @AppStorage("language") private var language: Language = .english
    var processResult: (SearchResult) -> Void
        
    var body: some View {
        List {
            Picker("Language", selection: $language) {
                ForEach(Language.allCases, id: \.rawValue) {
                    Text($0.description).tag($0)
                }
            }
            if !service.seriesResults.isEmpty {
                Section("Series") {
                    ForEach(service.seriesResults.prefix(8), id: \.tmdbID) { series in
                        resultItem(result: series)
                    }
                }
            }
            if !service.movieResults.isEmpty {
                Section("Movies") {
                    ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                        resultItem(result: movie)
                    }
                }
            }
        }
        .searchable(text: $service.query, prompt: "Search TV animation or movies...")
        .onSubmit(of: .search) {
            updateSearchResults()
        }
        .listStyle(.inset)
        .onAppear { updateSearchResults() }
        .onChange(of: language) { updateSearchResults() }
    }
    
    func updateSearchResults() {
        if !service.query.isEmpty {
            let currentQuery = self.service.query
            let fetcher = service.fetcher
            Task {
                let movies = try await fetcher.searchMovies(name: currentQuery, language: language)
                let tvSeries = try await fetcher.searchTVSeries(name: currentQuery, language: language)
                
                var moviesResults = movies.map { movie in
                    SearchResult(name: movie.title,
                              overview: movie.overview,
                              posterPath: movie.posterPath,
                              tmdbID: movie.id,
                              onAirDate: movie.releaseDate,
                              typeMetadata: .movie)
                }
                var tvSeriesResults = tvSeries.map { series in
                    SearchResult(name: series.name,
                              overview: series.overview,
                              posterPath: series.posterPath,
                              tmdbID: series.id,
                              onAirDate: series.firstAirDate,
                              typeMetadata: .tvSeries)
                }
                
                // The poster displayed here is small and we use smaller sizes
                // to reduce network overhead.
                try await moviesResults.updatePosterURLs(width: 200)
                try await tvSeriesResults.updatePosterURLs(width: 200)
                
                if currentQuery == service.query {
                    withAnimation {
                        service.movieResults = moviesResults
                        service.seriesResults = tvSeriesResults
                    }
                }
            }
        }
    }
    
    private func resultItem(result: SearchResult) -> some View {
        HStack {
            if let url = result.posterURL {
                KFImage(url)
                    .resizable()
                    .fade(duration: 0.3)
                    .placeholder {
                        ProgressView()
                    }
                    .cacheMemoryOnly()
                    .cancelOnDisappear(true)
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 6))
                    .frame(width: 60, height: 90)
            }
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
        .onTapGesture { processResult(result) }
    }
}

@Observable
class SearchService {
    let fetcher: InfoFetcher = .init(language: .english)
    var query: String = ""
    var movieResults: [SearchResult] = []
    var seriesResults: [SearchResult] = []
}

#Preview {
    NavigationStack {
        SearchPage { _ in }
    }
}
