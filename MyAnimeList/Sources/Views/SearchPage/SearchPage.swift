//
//  SearchPage.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/30.
//

import SwiftUI
import Kingfisher
import Collections

struct SearchPage: View {
    @State var service: SearchService
    @AppStorage(.searchPageLanguage) private var language: Language = .english
    
    init(query: String = UserDefaults.standard.string(forKey: .searchPageQuery) ?? "",
         processResults: @escaping (OrderedSet<SearchResult>) -> Void) {
        self._service = .init(initialValue: .init(query: query, processResults: processResults))
    }

    var body: some View {
        List {
            Picker("Language", selection: $language) {
                ForEach(Language.allCases, id: \.rawValue) {
                    Text(LocalizedStringKey($0.description)).tag($0)
                }
            }
            if service.status == .done {
                results
            }
        }
        .environment(service)
        .listStyle(.inset)
        .searchable(text: $service.query, prompt: "Search TV animation or movies...")
        .overlay(alignment: .bottom) {
            submitMenu
                .offset(y: -30)
        }
        .onSubmit(of: .search) { updateResults() }
        .onChange(of: language, initial: true) { updateResults() }
        .animation(.default, value: service.status)
    }
    
    @ViewBuilder
    private var results: some View {
        if !service.seriesResults.isEmpty {
            Section("Series") {
                ForEach(service.seriesResults.prefix(8), id: \.tmdbID) { series in
                    SeriesResultItem(series: series)
                }
            }
        }
        if !service.movieResults.isEmpty {
            Section("Movies") {
                ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                    MovieResultItem(movie: movie)
                }
            }
        }
    }
    
    @ViewBuilder
    private var submitMenu: some View {
        if service.registeredCount != 0 {
            Button("Add...") {
                service.submit()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .shadow(color: .blue, radius: 8)
            .tint(.blue)
            .transition(.opacity.animation(.interactiveSpring(duration: 0.3)))
        }
    }
    
    private func updateResults() {
        service.updateResults(language: language)
    }
}

#Preview {
    NavigationStack {
        SearchPage(query: "K-on!") { results in
            print(results)
        }
    }
}
