//
//  SearchPage.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/30.
//

import SwiftUI
import Kingfisher

struct SearchPage: View {
    @State private var query: String = "K-on"
    @State private var results: [BasicInfo] = []
    @AppStorage("language") private var language: Language = .english
    
    @State private var isSeriesExpanded: Bool = true
    
    private var movies: [BasicInfo] { results.filter { $0.entryType == .movie } }
    private var series: [BasicInfo] { results.filter { $0.entryType == .tvSeries } }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            List {
                Picker("Language", selection: $language) {
                    ForEach(Language.allCases, id: \.rawValue) {
                        Text($0.description).tag($0)
                    }
                }
                Section("Series") {
                    ForEach(series.prefix(8), id: \.tmdbId) { series in
                        SearchItem(info: series)
                    }
                }
                Section("Movies") {
                    ForEach(movies.prefix(8), id: \.tmdbId) { movie in
                        SearchItem(info: movie)
                    }
                }
            }
            .searchable(text: $query, prompt: "Search TV animation or movies...")
            .onSubmit(of: .search) {
                updateSearchResults()
            }
            .listStyle(.plain)
        }
        .onAppear { updateSearchResults() }
        .onChange(of: language) { updateSearchResults() }
    }
    
    func updateSearchResults() {
        if !query.isEmpty {
            Task {
                let currentQuery = self.query
                
                let fetcher = InfoFetcher.shared
                await fetcher.changeLanguage(language)
                let movies = try await fetcher.searchMovies(name: currentQuery)
                let tvSeries = try await fetcher.searchTVSeries(name: currentQuery)
                
                var moviesInfo = movies.map { movie in
                    BasicInfo(name: movie.title,
                                     overview: movie.overview,
                                     posterPath: movie.posterPath,
                                     tmdbId: movie.id,
                                     onAirDate: movie.releaseDate,
                                     entryType: .movie)
                }
                var tvSeriesInfo = tvSeries.map { series in
                    BasicInfo(name: series.name,
                              overview: series.overview,
                              posterPath: series.posterPath,
                              tmdbId: series.id,
                              onAirDate: series.firstAirDate,
                              entryType: .tvSeries)
                }
                
                // The poster displayed here is small and we use smaller sizes
                // to reduce network overhead.
                try await moviesInfo.updatePosterURLs(width: 200)
                try await tvSeriesInfo.updatePosterURLs(width: 200)

                await MainActor.run {
                    if currentQuery == query {
                        withAnimation {
                            results = moviesInfo + tvSeriesInfo
                        }
                    }
                }
            }
        }
    }
}

struct SearchItem: View {
    var info: BasicInfo
    
    var body: some View {
        HStack {
            if let url = info.posterURL {
                KFImage(url)
                    .resizable()
                    .fade(duration: 0.3)
                    .placeholder {
                        ProgressView()
                    }
                    .diskCacheExpiration(.days(1))
                    .clipShape(.rect(cornerRadius: 6))
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 90)
                    .animation(.default, value: url)
            }
            VStack(alignment: .leading) {
                Text(info.name)
                    .bold()
                    .lineLimit(1)
                if let date = info.onAirDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .padding(.bottom, 1)
                }
                Text(info.overview ?? "No overview available")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .lineLimit(3)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchPage()
    }
}
