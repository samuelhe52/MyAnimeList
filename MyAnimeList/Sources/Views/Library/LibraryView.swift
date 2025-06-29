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
    
    @State private var isSearching = false
    @State private var changeAPIKey = false
    @State private var showCacheAlert = false
    @State private var showClearAllAlert = false
    @State private var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    @State private var scrollState = ScrollState()
    @State private var newEntriesAddedToggle = false
    
    @AppStorage(.useCurrentLocaleForAnimeInfoLanguage) var useCurrentLocaleForAnimeInfoLanguage: Bool = true
    
    var body: some View {
        NavigationStack {
            Color(.secondarySystemBackground)
                .ignoresSafeArea(.all)
                .overlay {
                    VStack {
                        LibraryGalleryView(store: store,
                                           scrolledID: $scrollState.scrolledID)
                        controls
                    }
                    .padding(.vertical)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .sensoryFeedback(.success, trigger: newEntriesAddedToggle)
                }
        }
    }
    
    @ViewBuilder
    private var controls: some View {
        HStack {
            filterAndSort
            Button("Search...") { isSearching = true }
                .buttonBorderShape(.capsule)
            settings
        }
        .buttonStyle(.bordered)
        .onChange(of: useCurrentLocaleForAnimeInfoLanguage) {
            if useCurrentLocaleForAnimeInfoLanguage {
                store.language = .current
            }
        }
        .sheet(isPresented: $isSearching) {
            NavigationStack {
                SearchPage { processResults($0) }
                .navigationTitle("Search TMDB")
                .navigationBarTitleDisplayMode(.inline)
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
    
    private var filterAndSort: some View {
        Menu {
            Toggle(isOn: $store.sortReversed) { Text("Reversed") }
            Picker("Sort", selection: $store.sortStrategy) {
                ForEach(LibraryStore.AnimeSortStrategy.allCases, id: \.self) { strategy in
                    Text(strategy.localizedStringResource).tag(strategy)
                }
            }.pickerStyle(.menu)
            Divider()
            Menu("Filter") {
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
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16))
                .padding(1.5)
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .menuActionDismissBehavior(.disabled)
    }
    
    private var settings: some View {
        Menu {
            apiConfigruation
            checkDiskUsageButton
            refreshInfosButton
            Divider()
            Toggle("Follow System", systemImage: "gear", isOn: $useCurrentLocaleForAnimeInfoLanguage)
            preferredAnimeInfoLanguagePicker
            Divider()
            deleteAllButton
        } label: {
            Image(systemName: "ellipsis").padding(.vertical, 7.5)
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .menuActionDismissBehavior(.disabled)
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
            let success = await store.newEntryFromSearchResults(results)
            if success {
                withAnimation {
                    newEntriesAddedToggle.toggle()
                    if let id = results.first?.tmdbID {
                        scrollState.scrolledID = id
                    }
                }
            }
        }
    }
}

#Preview {
    // dataProvider could be changed to .forPreview for memory-only storage.
    // Uncomment the task below to generate template entries.
    @Previewable let store = LibraryStore(dataProvider: .default)
    LibraryView(store: store)
//        .onAppear {
//            for index in 0..<50 {
//                let info = AnimeEntry.template(id: index).basicInfo
//                store.newEntryFromBasicInfo(info)
//            }
//        }
}
