//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import Kingfisher
import SwiftData
import DataProvider
import Collections

struct LibraryView: View {
    @Bindable var store: LibraryStore
    @Environment(\.dataHandler) var dataHandler
    
    @State private var isSearching = false
    @State private var changeAPIKey = false
    @State private var showCacheAlert = false
    @State private var showClearAllAlert = false
    @State private var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    @State private var scrollState = ScrollState()
    @State private var newEntriesAddedToggle = false
    @State private var favoriteToggle = false
    
    @AppStorage(.useCurrentLocaleForAnimeInfoLanguage) var useCurrentLocaleForAnimeInfoLanguage: Bool = true
    @AppStorage(.libraryViewStyle) var libraryViewStyle: LibraryViewStyle = .gallery
    
    var body: some View {
        NavigationStack {
            mainContent
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Picker("View Style", selection: $libraryViewStyle) {
                            ForEach(LibraryViewStyle.allCases, id: \.self) { style in
                                Label(style.nameKey, systemImage: style.systemImageName).tag(style)
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .status) {
                        sortOptions
                        filterOptions
                    }
                    ToolbarItem(placement: .bottomBar) {
                        if let scrolledID = scrollState.scrolledID,
                           let entry = store.libraryOnDisplay.entryWithID(scrolledID) {
                            toggleFavoriteButton(for: entry)
                                .disabled(libraryViewStyle != .gallery)
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        searchButton
                        settings
                    }
                }
                .sensoryFeedback(.success, trigger: newEntriesAddedToggle)
        }
    }
    
    private func toggleFavoriteButton(for entry: AnimeEntry) -> some View {
        Button {
            dataHandler?.toggleFavorite(entry: entry)
            favoriteToggle.toggle()
        } label: {
            if entry.favorite {
                Image(systemName: "heart.fill")
            } else {
                Image(systemName: "heart")
            }
        }
        .sensoryFeedback(.impact, trigger: favoriteToggle)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch libraryViewStyle {
        case .gallery:
            LibraryGalleryView(store: store,
                               scrolledID: $scrollState.scrolledID)
            .ignoresSafeArea(.keyboard)
            .scenePadding(.vertical)
            .navigationTitle("\(store.libraryOnDisplay.count) Anime")
            .navigationBarTitleDisplayMode(.inline)
        case .list:
            LibraryListView(store: store)
        }
    }
    
    private var searchButton: some View {
        Button("Search...", systemImage: "magnifyingglass.circle") { isSearching = true }
            .sheet(isPresented: $isSearching) {
                NavigationStack {
                    SearchPage { processResults($0) }
                        .navigationTitle("Search TMDB")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
    }
    
    @ViewBuilder
    private var settings: some View {
        Menu {
            deleteAllButton
            Divider()
            Toggle("Follow System", systemImage: "gear", isOn: $useCurrentLocaleForAnimeInfoLanguage)
            preferredAnimeInfoLanguagePicker
            Divider()
            apiConfigruation
            checkDiskUsageButton
            refreshInfosButton
        } label: {
            Image(systemName: "ellipsis.circle").padding(.vertical, 7.5)
        }
        .menuOrder(.priority)
        .onChange(of: useCurrentLocaleForAnimeInfoLanguage) {
            if useCurrentLocaleForAnimeInfoLanguage {
                store.language = .current
            }
        }
        .alert("Delete all animes?", isPresented: $showClearAllAlert) {
            Button("Delete", role: .destructive) {
                store.clearLibrary()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Disk Usage", isPresented: $showCacheAlert, presenting: cacheSizeResult,
               actions: { result in
            switch result {
            case .success:
                Button("Clear") {
                    KingfisherManager.shared.cache.clearCache()
                }
                Button("Cancel", role: .cancel) {}
            case .failure:
                Button("OK") { }
            }
        }, message: { result in
            switch result {
            case .success(let size):
                Text("Size: \(Double(size) / 1024 / 1024, specifier: "%.2f") MB")
            case .failure(let error):
                Text(error.localizedDescription)
            }
        })
        .sheet(isPresented: $changeAPIKey) {
            TMDbAPIConfigurator(isEditing: true)
                .presentationDetents([.medium, .large])
        }
    }
    
    private var sortOptions: some View {
        Menu {
            Toggle("Reversed", systemImage: "arrow.counterclockwise.circle", isOn: $store.sortReversed)
            Picker("Sort", selection: $store.sortStrategy) {
                ForEach(LibraryStore.AnimeSortStrategy.allCases, id: \.self) { strategy in
                    Text(strategy.localizedStringResource).tag(strategy)
                }
            }
            .pickerStyle(.menu)
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16))
                .padding(1.5)
        }
        .menuActionDismissBehavior(.disabled)
    }
    
    private var filterOptions: some View {
        Menu("Filter", systemImage: "line.3.horizontal.decrease") {
            ForEach(LibraryStore.AnimeFilter.allCases, id: \.self) { filter in
                Toggle(isOn: .init(get: {
                    return store.filters.contains(filter)
                }, set: {
                    if $0 {
                        store.filters.insert(filter)
                    } else {
                        store.filters.remove(filter)
                    }
                }), label: { Text(filter.name) })
            }
            Divider()
            Toggle("All", isOn: .init(get: { store.filters.isEmpty }, set: {
                if $0 { store.filters.removeAll() }
            }))
        }
    }
    
    private var preferredAnimeInfoLanguagePicker: some View {
        Picker(selection: $store.language) {
            ForEach(Language.allCases, id: \.rawValue) { language in
                Text(language.localizedStringResource).tag(language)
            }
        } label: {
            Label("Anime Info Language", systemImage: "globe")
        }
        .disabled(useCurrentLocaleForAnimeInfoLanguage)
        .pickerStyle(.menu)
    }
    
    private var deleteAllButton: some View {
        Button("Delete All Animes", systemImage: "trash", role: .destructive) {
            showClearAllAlert = true
        }
    }
    
    private var checkDiskUsageButton: some View {
        Button("Check Disk Usage", systemImage: "archivebox") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                DispatchQueue.main.async {
                    cacheSizeResult = result
                    showCacheAlert = true
                }
            }
        }
    }
    
    private var apiConfigruation: some View {
        Button("Change API Key", systemImage: "person.badge.key") { changeAPIKey = true }
    }
    
    private var refreshInfosButton: some View {
        Button("Refresh Infos", systemImage: "arrow.clockwise") {
            store.refreshInfos()
        }
    }
    
    private func processResults(_ results: OrderedSet<SearchResult>) {
        isSearching = false
        Task {
            ToastCenter.global.loading = true
            let success = await store.newEntryFromSearchResults(results)
            if success {
                ToastCenter.global.loading = false
                withAnimation {
                    newEntriesAddedToggle.toggle()
                    if let id = results.first?.tmdbID {
                        scrollState.scrolledID = id
                    }
                }
            }
        }
    }
    
    private func customButtonStyle<S: Shape>(in shape: S) -> CustomBGBorderedButtonStyle<Material, S> {
        CustomBGBorderedButtonStyle(.ultraThinMaterial, backgroundIn: shape)
    }
    
    enum LibraryViewStyle: String, CaseIterable {
        case gallery
        case list
        
        var nameKey: LocalizedStringKey {
            switch self {
            case .gallery: "Gallery"
            case .list: "List"
            }
        }
        
        var systemImageName: String {
            switch self {
            case .gallery: "photo.on.rectangle.angled"
            case .list: "list.bullet.rectangle.portrait"
            }
        }
    }
}

#Preview {
    // dataProvider could be changed to .forPreview for memory-only storage.
    // Uncomment the task below to generate template entries.
    @Previewable let store = LibraryStore(dataProvider: .forPreview)
    LibraryView(store: store)
        .onAppear {
            DataProvider.forPreview.generateEntriesForPreview()
        }
        .environment(\.dataHandler, DataProvider.forPreview.dataHandler)
}
