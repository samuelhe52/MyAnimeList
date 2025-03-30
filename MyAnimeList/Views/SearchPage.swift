//
//  SearchPage.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/30.
//

import SwiftUI

struct SearchPage: View {
    @State private var query: String = "K-on"
    @State private var results: [BasicInfo] = []
    
    @State private var isSeriesExpanded: Bool = true
    
    private var movies: [BasicInfo] { results.filter { $0.entryType == .movie } }
    private var series: [BasicInfo] { results.filter { $0.entryType == .tvSeries } }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("Search any TV animation or movies...", text: $query)
                .autocorrectionDisabled(true)
                .padding(.horizontal)
            Divider()
            List {
                Section("Series") {
                    ForEach(series.prefix(8), id: \.tmdbId) { series in
                        Text(series.name)
                    }
                }
                Section("Movies") {
                    ForEach(movies.prefix(8), id: \.tmdbId) { movie in
                        Text(movie.name)
                    }
                }
            }
        }
        .onChange(of: query) { updateSearchResults() }
        .onAppear { updateSearchResults() }
    }
    
    func updateSearchResults() {
        if !query.isEmpty {
            Task {
                let currentQuery = self.query
                
                let fetcher = InfoFetcher.shared
                let movies = try await fetcher.searchMovies(name: currentQuery)
                let tvSeries = try await fetcher.searchTVSeries(name: currentQuery)
                
                let moviesInfo = movies.map { movie in
                    BasicInfo(name: movie.title, tmdbId: movie.id, entryType: .movie)
                }
                let tvSeriesInfo = tvSeries.map { series in
                    BasicInfo(name: series.name, tmdbId: series.id, entryType: .tvSeries)
                }
                
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

#Preview {
    SearchPage()
}
