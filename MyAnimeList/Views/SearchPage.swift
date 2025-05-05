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
    @AppStorage(.searchPageLanguage) private var language: Language = .english
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
                let series = Array(service.seriesResults.keys) as [BasicInfo]
                ForEach(series, id: \.tmdbID) { series in
                    SeriesResultItem(result: series,
                                     seasons: service.seriesResults[series] ?? [],
                                     processResult: processResult)
                }
            }
        }
        if !service.movieResults.isEmpty {
            Section("Movies") {
                ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                    MovieResultItem(result: movie, processResult: processResult)
                }
            }
        }
    }
    
    private func updateResults() {
        Task { try await service.updateSearchResults(language: language) }
    }
}

struct SeriesResultItem: View {
    let result: SearchResult
    let seasons: [BasicInfo]
    let processResult: (SearchResult) -> Void
    var selectedSeason: BasicInfo? {
        seasons.first {
            $0.typeMetadata.seasonNumber == selectedSeasonNumber
        }
    }
    @State private var selectedSeasonNumber: Int = 1
    
    var body: some View {
        HStack {
            poster(url: selectedSeason?.posterURL)
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 6))
                .frame(width: 60, height: 90)
            VStack(alignment: .leading) {
                HStack {
                    Text(result.name)
                        .bold()
                        .lineLimit(1)
                    Spacer()
                    Picker("", selection: $selectedSeasonNumber) {
                        ForEach(seasons) { season in
                            pickerItem(season: season)
                        }
                    }.frame(height: 0)
                }
                if let date = selectedSeason?.onAirDate {
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
        .onTapGesture { processResult(selectedSeason ?? result) }
        .animation(.default, value: selectedSeasonNumber)
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
    
    
    private func pickerItem(season: BasicInfo) -> some View {
        let seasonNumber = season.typeMetadata.seasonNumber ?? 0
        return Text(season.name).tag(seasonNumber)
    }
}

struct MovieResultItem: View {
    let result: SearchResult
    let processResult: (SearchResult) -> Void
    
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
        .onTapGesture { processResult(result) }
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

#Preview {
    @Previewable @State var service = SearchService(query: "K-on!")
    
    NavigationStack {
        SearchPage(service: service) { result in
            print(result)
        }
    }
}
