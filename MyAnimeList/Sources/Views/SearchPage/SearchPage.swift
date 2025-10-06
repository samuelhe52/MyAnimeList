//
//  SearchPage.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/30.
//

import Collections
import SwiftUI

enum SearchMode: String, CaseIterable, CustomLocalizedStringResourceConvertible {
    case tmdb
    case library

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .tmdb: return "TMDb"
        case .library: return "Library"
        }
    }
}

/// Main search page that coordinates between TMDb and Library search modes.
struct SearchPage: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(.searchMode) private var mode: SearchMode = .tmdb

    // View models owned by SearchPage
    @State private var tmdbSearchService: TMDbSearchService
    @State private var librarySearchService: LibrarySearchService

    // Callbacks for TMDb search interactions
    private let onDuplicateTapped: (Int) -> Void
    private let checkDuplicate: (Int) -> Bool

    init(
        onDuplicateTapped: @escaping (_ tappedID: Int) -> Void,
        checkDuplicate: @escaping (_ tmdbID: Int) -> Bool,
        processTMDbSearchResults: @escaping (OrderedSet<SearchResult>) -> Void,
        jumpToEntryInLibrary: @escaping (Int) -> Void = { _ in }
    ) {
        self.onDuplicateTapped = onDuplicateTapped
        self.checkDuplicate = checkDuplicate

        // Initialize view models
        let query = UserDefaults.standard.string(forKey: .searchPageQuery) ?? ""
        self._tmdbSearchService = State(
            initialValue: TMDbSearchService(
                query: query,
                processResults: processTMDbSearchResults
            ))
        self._librarySearchService = State(
            initialValue: LibrarySearchService(
                query: query,
                jumpToEntryInLibrary: jumpToEntryInLibrary
            ))
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Scope", selection: $mode) {
                ForEach(SearchMode.allCases, id: \.self) { scope in
                    Text(scope.localizedStringResource)
                        .font(.title2)
                        .tag(scope)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .glassEffect(.regular)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch mode {
            case .tmdb:
                TMDbSearchContent(
                    onDuplicateTapped: onDuplicateTapped,
                    checkDuplicate: checkDuplicate
                )
                .environment(tmdbSearchService)
                .transition(.move(edge: .leading))

            case .library:
                LibrarySearchContent()
                    .environment(librarySearchService)
                    .transition(.move(edge: .trailing))
            }
        }
        .toolbar {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
        }
        .animation(.default, value: mode)
    }
}

#Preview {
    NavigationStack {
        SearchPage(
            onDuplicateTapped: { _ in },
            checkDuplicate: { _ in true },
            processTMDbSearchResults: { results in
                print(results)
            }
        )
    }
}
