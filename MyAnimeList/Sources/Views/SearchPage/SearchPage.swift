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
    @Environment(\.dismiss) var dismiss
    @AppStorage(.searchPageLanguage) private var language: Language = .english
    
    private let onDuplicateTapped: (Int) -> Void
    private let checkDuplicate: (Int) -> Bool
    
    init(query: String = UserDefaults.standard.string(forKey: .searchPageQuery) ?? "",
         onDuplicateTapped: @escaping (_ tappedID: Int) -> Void,
         checkDuplicate: @escaping (_ tmdbID: Int) -> Bool,
         processResults: @escaping (OrderedSet<SearchResult>) -> Void) {
        self._service = .init(initialValue: .init(query: query, processResults: processResults))
        self.onDuplicateTapped = onDuplicateTapped
        self.checkDuplicate = checkDuplicate
    }
    
    var body: some View {
        Group {
            switch service.status {
            case .loaded: List {
                languagePicker
                results
            }
            case .loading: ProgressView()
            case .error(let error):
                VStack {
                    Button("Reload", systemImage: "arrow.clockwise.circle") {
                        updateResults()
                    }
                    .padding(.bottom)
                    Text("An error occurred while loading results.")
                    Text("Check your internet connection.")
                        .padding(.bottom)
                    Text("Error: \(error.localizedDescription)")
                        .font(.caption)
                }
                .multilineTextAlignment(.center)
            }
        }
        .environment(service)
        .listStyle(.inset)
        .searchable(text: $service.query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search TV animation or movies...")
//        .toolbar {
//            ToolbarItem(placement: .status) {
//                Picker("Language", selection: $language) {
//                    ForEach(Language.allCases, id: \.rawValue) { language in
//                        Text(language.localizedStringResource).tag(language)
//                    }
//                }
//            }
//        }
        .overlay(alignment: .bottom) {
            submitMenu
                .offset(y: -30)
        }
        .onSubmit(of: .search) { updateResults() }
        .onChange(of: language, initial: true) { updateResults() }
        .animation(.default, value: service.status)
    }
    
    @ViewBuilder
    private var languagePicker: some View {
        Picker("Language", selection: $language) {
            ForEach(Language.allCases, id: \.rawValue) { language in
                Text(language.localizedStringResource).tag(language)
            }
        }
    }
    
    @ViewBuilder
    private var results: some View {
        if !service.seriesResults.isEmpty {
            Section("TV Series") {
                ForEach(service.seriesResults.prefix(8), id: \.tmdbID) { series in
                    let isDuplicate = checkDuplicate(series.tmdbID)
                    SeriesResultItem(series: series)
                        .indicateAlreadyAdded(added: isDuplicate,
                                              message: alreadyAddedMessage)
                        .onTapGesture {
                            if isDuplicate { onDuplicateTapped(series.tmdbID) }
                        }
                }
            }
        }
        if !service.movieResults.isEmpty {
            Section("Movies") {
                ForEach(service.movieResults.prefix(8), id: \.tmdbID) { movie in
                    let isDuplicate = checkDuplicate(movie.tmdbID)
                    MovieResultItem(movie: movie)
                        .indicateAlreadyAdded(added: isDuplicate,
                                              message: alreadyAddedMessage)
                        .onTapGesture {
                            if isDuplicate { onDuplicateTapped(movie.tmdbID) }
                        }
                }
            }
        }
    }
    
    private var alreadyAddedMessage: LocalizedStringKey { "Already in library." }
    
    @ViewBuilder
    private var submitMenu: some View {
        if service.registeredCount != 0 {
            Button("Add To Library...") {
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

fileprivate struct AlreadyAddedIndicatorModifier: ViewModifier {
    var added: Bool
    var message: LocalizedStringKey
    
    func body(content: Content) -> some View {
        if added {
            content
                .blur(radius: 3)
                .disabled(true)
                .overlay {
                    Text(message)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(.ultraThinMaterial, in: .buttonBorder)
                        .font(.callout)
                }
        } else {
            content
        }
    }
}

fileprivate extension View {
    func indicateAlreadyAdded(added: Bool = false,
                              message: LocalizedStringKey) -> some View {
        modifier(AlreadyAddedIndicatorModifier(added: added, message: message))
    }
}

#Preview {
    NavigationStack {
        SearchPage(query: "K-on!",
                   onDuplicateTapped: { _ in },
                   checkDuplicate: { _ in false },
                   processResults: { results in
            print(results)
        })
    }
}
