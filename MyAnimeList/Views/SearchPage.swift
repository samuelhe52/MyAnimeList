//
//  SearchPage.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/30.
//

import SwiftUI
import Kingfisher

struct SearchPage: View {
    @State var service: SearchService = .init()
    @AppStorage("language") private var language: Language = .english
    
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
                        SearchItem(info: series)
                    }
                }
            }
            if !service.movieResults.isEmpty {
                Section("Movies") {
                    ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                        SearchItem(info: movie)
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
            Task {
                let currentQuery = self.service.query
                
                let fetcher = service.fetcher
                await fetcher.changeLanguage(language)
                let movies = try await fetcher.searchMovies(name: currentQuery)
                let tvSeries = try await fetcher.searchTVSeries(name: currentQuery)
                
                var moviesInfo = movies.map { movie in
                    BasicInfo(name: movie.title,
                                     overview: movie.overview,
                                     posterPath: movie.posterPath,
                                     tmdbID: movie.id,
                                     onAirDate: movie.releaseDate,
                                     typeMetadata: .movie)
                }
                var tvSeriesInfo = tvSeries.map { series in
                    BasicInfo(name: series.name,
                              overview: series.overview,
                              posterPath: series.posterPath,
                              tmdbID: series.id,
                              onAirDate: series.firstAirDate,
                              typeMetadata: .tvSeries)
                }
                
                // The poster displayed here is small and we use smaller sizes
                // to reduce network overhead.
                try await moviesInfo.updatePosterURLs(width: 200)
                try await tvSeriesInfo.updatePosterURLs(width: 200)

                await MainActor.run {
                    if currentQuery == service.query {
                        withAnimation {
                            service.movieResults = moviesInfo
                            service.seriesResults = tvSeriesInfo
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
                    .cacheMemoryOnly()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 6))
                    .frame(width: 60, height: 90)
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

@Observable
class SearchService {
    var fetcher: InfoFetcher = .init(language: .english)
    var query: String = ""
    var movieResults: [BasicInfo] = []
    var seriesResults: [BasicInfo] = []
}

#Preview {
    NavigationStack {
        SearchPage()
    }
}
