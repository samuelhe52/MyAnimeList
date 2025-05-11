//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import Kingfisher
import SwiftData

struct LibraryView: View {
    var store: LibraryStore
    
    @State private var isSearching: Bool = false
    @State private var changeAPIKey: Bool = false
    @State private var showCacheAlert = false
    @State private var showClearAllAlert = false
    @State private var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    @State private var scrollState = ScrollState()

    @AppStorage(.preferredMetadataLanguage) var language: Language = .japanese
    
    
    init(store: LibraryStore) {
        self.store = store
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                LibraryScrollView(store: store,
                                  scrolledID: $scrollState.scrolledID)
                controls
            }
            .padding(.vertical)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    @ViewBuilder
    private var controls: some View {
        HStack{
            Button("Search...") { isSearching = true }
            Menu {
                checkCacheButton
                refreshInfosButton
                changeAPIKeyButton
                clearAllButton
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.bordered)
        .sheet(isPresented: $isSearching) {
            NavigationStack {
                SearchPage(service: .init()) { result in
                    Task { await processSearchResult(result) }
                }
                .navigationTitle("Search TMDB")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("Clear all entries?", isPresented: $showClearAllAlert) {
            Button("Clear", role: .destructive) {
                Task {
                    do  {
                        try await store.clearLibrary()
                    } catch {
                        ToastCenter.global.completionState = .init(state: .failed,
                                                                   message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Disk Cache", isPresented: $showCacheAlert, presenting: cacheSizeResult,
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
            TMDbAPIKeyEditor(isEditing: true)
                .presentationDetents([.medium, .large])
        }
    }
    
    private var clearAllButton: some View {
        Button("Clear all", systemImage: "trash", role: .destructive) {
            showClearAllAlert = true
        }
    }
    
    private var checkCacheButton: some View {
        Button("Check Cache", systemImage: "archivebox") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                DispatchQueue.main.async {
                    cacheSizeResult = result
                    showCacheAlert = true
                }
            }
        }
    }
        
    private var changeAPIKeyButton: some View {
        Button("Change API Key", systemImage: "key") { changeAPIKey = true }
    }
    
    private var refreshInfosButton: some View {
        Button("Refresh Infos", systemImage: "arrow.clockwise") {
            Task { try await store.refreshInfos() }
        }
    }
    
    private func processSearchResult(_ result: SearchResult) async {
        isSearching = false
        do {
            try await store.newEntryFromInfo(info: result)
        } catch {
            ToastCenter.global.completionState = .init(state: .failed,
                                                       message: error.localizedDescription)
            return
        }
        withAnimation {
            scrollState.scrolledID = result.tmdbID
        }
    }
}

private struct LibraryScrollView: View {
    let store: LibraryStore
    @Binding var scrolledID: Int?

    var body: some View {
        GeometryReader { geometry in
            let isHorizontal = geometry.size.width < geometry.size.height
            if !store.library.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(store.library, id: \.tmdbID) { entry in
                            AnimeEntryCard(entry: entry, onDelete: {
                                Task { try await store.deleteEntry(withID: entry.id) }
                            })
                            .containerRelativeFrame(isHorizontal ? .horizontal : .vertical)
                            .transition(.opacity)
                            .onScrollVisibilityChange { _ in }
                        }
                    }.scrollTargetLayout()
                }
                .scrollPosition(id: $scrolledID)
                .scrollTargetBehavior(.viewAligned)
            } else {
                Color.clear
                    .overlay {
                        Text("The library is empty.")
                    }
            }
        }
    }
}

// This is where we place debug-specific code.
extension LibraryScrollView {
    private func mockDelete(withID id: PersistentIdentifier) {
        store.mockDeleteEntry(withID: id)
    }
}

#Preview {
    // dataProvider could be changed to .forPreview for memory-only storage.
    // Uncomment the task below to generate template entries.
    @Previewable let store = LibraryStore(dataProvider: .forPreview)
    LibraryView(store: store)
//        .task {
//            await withTaskGroup(of: Void.self) { group in
//                for index in 0..<50 {
//                    group.addTask {
//                        let info = AnimeEntry.template(id: index).basicInfo
//                        try? await store.newEntryFromInfo(info: info)
//                    }
//                }
//                await group.waitForAll()
//            }
//        }
}
