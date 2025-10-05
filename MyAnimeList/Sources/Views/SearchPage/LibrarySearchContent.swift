//
//  LibrarySearchContent.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/10/5.
//

import SwiftUI
import DataProvider

/// View responsible for displaying library search results and handling library-specific interactions.
struct LibrarySearchContent: View {
    @Environment(LibrarySearchService.self) private var librarySearchService: LibrarySearchService
    
    var body: some View {
        @Bindable var librarySearchService = librarySearchService
        
        VStack {
            switch librarySearchService.status {
            case .loaded:
                libraryResults
            case .loading:
                Spacer()
                ProgressView()
                Spacer()
            case .error(let error):
                Spacer()
                VStack {
                    Button("Reload", systemImage: "arrow.clockwise.circle") {
                        librarySearchService.updateResults()
                    }
                    .padding(.bottom)
                    Text("An error occurred while loading results.")
                    Text("Error: \(error.localizedDescription)")
                        .font(.caption)
                }
                .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .listStyle(.inset)
        .searchable(text: $librarySearchService.query,
                   placement: .navigationBarDrawer(displayMode: .automatic),
                   prompt: "Search in your library...")
        .onSubmit(of: .search) { librarySearchService.updateResults() }
        .onAppear {
            if librarySearchService.results.isEmpty {
                librarySearchService.updateResults()
            }
        }
        .animation(.default, value: librarySearchService.status)
    }
    
    @ViewBuilder
    private var libraryResults: some View {
        if librarySearchService.results.isEmpty {
            ContentUnavailableView("No Results", 
                                  systemImage: "magnifyingglass",
                                  description: Text("Try a different search term"))
        } else {
            List {
                ForEach(librarySearchService.results, id: \.tmdbID) { result in
                    AnimeEntryListRow(entry: result)
                        .onTapGesture {
                            librarySearchService.jumpToEntryInLibrary(result.tmdbID)
                        }
                }
            }
        }
    }
}
