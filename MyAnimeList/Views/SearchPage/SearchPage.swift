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
    var processResults: (Set<SearchResult>) -> Void
    @State var resultsToSubmit: Set<SearchResult> = []

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
        .listStyle(.inset)
        .searchable(text: $service.query, prompt: "Search TV animation or movies...")
        .overlay(alignment: .bottom) {
            submitMenu
                .offset(y: -40)
        }
        .onSubmit(of: .search) { updateResults() }
        .onChange(of: language, initial: true) { updateResults() }
        .animation(.default, value: service.status)
        .animation(.default, value: resultsToSubmit)
    }
    
    @ViewBuilder
    private var results: some View {
        if !service.seriesResults.isEmpty {
            Section("Series") {
                ForEach(service.seriesResults.prefix(8), id: \.tmdbID) { series in
                    SeriesResultItem(series: series,
                                     resultsToSubmit: $resultsToSubmit,
                                     fetcher: service.fetcher)
                }
            }
        }
        if !service.movieResults.isEmpty {
            Section("Movies") {
                ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                    MovieResultItem(movie: movie, resultsToSubmit: $resultsToSubmit)
                }
            }
        }
    }
    
    private var submitMenu: some View {
        Menu {
            Text("\(resultsToSubmit.count) selected")
            Button("Add to library") {
                processResults(resultsToSubmit)
            }.disabled(resultsToSubmit.isEmpty)
        } label: {
            Text("Add...")
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(.blue)
    }
    
    private func updateResults() {
        Task { try await service.updateSearchResults(language: language) }
    }
}

#Preview {
    @Previewable @State var service = SearchService(query: "K-on!")
    
    NavigationStack {
        SearchPage(service: service) { results in
            print(results)
        }
    }
}
