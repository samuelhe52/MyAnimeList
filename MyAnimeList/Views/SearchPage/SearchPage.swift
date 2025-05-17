//
//  SearchPage.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/30.
//

import SwiftUI
import Kingfisher

struct SearchPage: View {
    @State var service: SearchService
    @AppStorage(.searchPageLanguage) private var language: Language = .english
    
    init(query: String = "", processResults: @escaping (Set<BasicInfo>) -> Void) {
        self._service = .init(initialValue: .init(query: query, processResults: processResults))
    }

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
                    SeriesResultItem(series: series).environment(service)
                }
            }
        }
        if !service.movieResults.isEmpty {
            Section("Movies") {
                ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                    MovieResultItem(movie: movie).environment(service)
                }
            }
        }
    }
    
    private var submitMenu: some View {
        Menu {
            Text("\(service.registeredCount) selected")
            Button("Add to library") {
                service.submit()
            }.disabled(service.registeredCount == 0)
        } label: {
            Text("Add...")
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .shadow(color: .blue, radius: 8)
    }
    
    private func updateResults() {
        Task { try await service.updateBasicInfos(language: language) }
    }
}

#Preview {
    NavigationStack {
        SearchPage(query: "K-on!") { results in
            print(results)
        }
    }
}
