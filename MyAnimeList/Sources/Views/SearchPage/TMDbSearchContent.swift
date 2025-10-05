//
//  TMDbSearchContent.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/10/5.
//

import SwiftUI
import Collections

/// View responsible for displaying TMDb search results and handling TMDb-specific interactions.
struct TMDbSearchContent: View {
    @Environment(TMDbSearchService.self) private var tmdbSearchService: TMDbSearchService
    @AppStorage(.searchTMDbLanguage) private var language: Language = .english
    
    private let onDuplicateTapped: (Int) -> Void
    private let checkDuplicate: (Int) -> Bool
    
    init(onDuplicateTapped: @escaping (Int) -> Void,
         checkDuplicate: @escaping (Int) -> Bool) {
        self.onDuplicateTapped = onDuplicateTapped
        self.checkDuplicate = checkDuplicate
    }
    
    var body: some View {
        @Bindable var tmdbSearchService = tmdbSearchService
        
        VStack {
            switch tmdbSearchService.status {
            case .loaded:
                List {
                    languagePicker
                    results
                }
            case .loading:
                Spacer()
                ProgressView()
                Spacer()
            case .error(let error):
                Spacer()
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
                Spacer()
            }
        }
        .listStyle(.inset)
        .searchable(text: $tmdbSearchService.query, 
                   placement: .navigationBarDrawer(displayMode: .automatic), 
                   prompt: "Search TV animation or movies...")
        .safeAreaInset(edge: .bottom) {
            submitMenu
                .offset(y: -30)
        }
        .onSubmit(of: .search) { updateResults() }
        .onChange(of: language, initial: true) { updateResults() }
        .animation(.default, value: tmdbSearchService.status)
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
        if tmdbSearchService.movieResults.isEmpty && tmdbSearchService.seriesResults.isEmpty {
            ContentUnavailableView("No Results", 
                                  systemImage: "magnifyingglass",
                                  description: Text("Try a different search term"))
        } else {
            seriesResults
            movieResults
        }
    }
    
    private var alreadyAddedMessage: LocalizedStringKey { "Already in library." }
    
    @ViewBuilder private var seriesResults: some View {
        if !tmdbSearchService.seriesResults.isEmpty {
            Section("TV Series") {
                ForEach(tmdbSearchService.seriesResults.prefix(8), id: \.tmdbID) { series in
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
    }

    @ViewBuilder private var movieResults: some View {
        if !tmdbSearchService.movieResults.isEmpty {
            Section("Movies") {
                ForEach(tmdbSearchService.movieResults.prefix(8), id: \.tmdbID) { movie in
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
    
    @ViewBuilder
    private var submitMenu: some View {
        if tmdbSearchService.registeredCount != 0 {
            Button("Add To Library...") {
                tmdbSearchService.submit()
            }
            .buttonStyle(.glassProminent)
            .shadow(color: .blue, radius: 5)
            .transition(.opacity.animation(.interactiveSpring(duration: 0.3)))
        }
    }
    
    private func updateResults() {
        tmdbSearchService.updateResults(language: language)
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
                        .glassEffect(.regular)
                        .shadow(radius: 5)
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
