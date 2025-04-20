//
//  LibraryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/12/8.
//

import SwiftUI
import Kingfisher
import Combine
import AlertToast
import SwiftData

struct LibraryView: View {
    var store: LibraryStore
    @State private var isSearching: Bool = false
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    @AppStorage("PreferredMetadataLanguage") var language: Language = .japanese
    
    @State private var scrolledID: Int?
    
    var body: some View {
        NavigationStack {
            library
            controls
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: UIDevice.orientationDidChangeNotification),
            perform: { _ in
                let orientation = UIDevice.current.orientation
                isLandscape = orientation.isLandscape
            }
        )
        .padding(.vertical)
        .onChange(of: scrolledID) {
            if let entry = store.library[scrolledID ?? 0] {
                print(entry.name)
            }
        }
    }
    
    @ViewBuilder
    private var library: some View {
        if !store.library.isEmpty {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(store.library, id: \.tmdbID) { entry in
                        card(entry: entry)
                    }
                }.scrollTargetLayout()
                
            }
            .scrollPosition(id: $scrolledID)
            .scrollTargetBehavior(.viewAligned)
            .animation(.default, value: store.library)
        } else {
            Text("The library is empty.")
        }
    }
    
    @State private var showCacheAlert = false
    @State private var showClearAllAlert = false
    @State private var cacheSizeResult: Result<UInt, KingfisherError>? = nil
    
    @ViewBuilder
    private var controls: some View {
        VStack{
            Button("Search...") { isSearching = true }
            HStack {
                checkCacheButton
                clearAllButton
            }
        }
        .buttonStyle(.bordered)
        .sheet(isPresented: $isSearching) {
            NavigationStack {
                SearchPage(service: .init()) { result in
                    Task { try await processSearchResult(result) }
                }
                .navigationTitle("Search TMDB")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private var clearAllButton: some View {
        Button("Clear all",  role: .destructive) {
            showClearAllAlert = true
        }
        .alert("Clear all entries?", isPresented: $showClearAllAlert) {
            Button("Clear", role: .destructive) {
                Task { try await store.clearLibrary() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var checkCacheButton: some View {
        Button("Check Cache") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                DispatchQueue.main.async {
                    cacheSizeResult = result
                    showCacheAlert = true
                }
            }
        }
        .alert(
            "Disk Cache",
            isPresented: $showCacheAlert,
            presenting: cacheSizeResult,
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
    }
    
    @State var showDeleteToast: Bool = false
    
    private func card(entry: AnimeEntry) -> some View {
        AnimeEntryCard(entry: entry)
            .transition(.move(edge: .top).combined(with: .opacity).animation(.default))
            .toast(isPresenting: $showDeleteToast, duration: 3, alert: {
                AlertToast(displayMode: .alert, type: .regular,
                           title: "Delete Entry?",
                           subTitle: "Tap me to confirm.")
            }, onTap: {
                Task { try await store.deleteEntry(withID: entry.id) }
            })
            .contextMenu {
                Button("Delete", role: .destructive) {
                    showDeleteToast = true
                }
            }
            .containerRelativeFrame(!isLandscape ? .horizontal
                                    : .vertical)

    }
    
    private func processSearchResult(_ result: SearchResult) async throws {
        isSearching = false
        try await store.newEntryFromSearchResult(result: result)
        withAnimation {
            scrolledID = result.tmdbID
        }
    }
}


// This is where we place debug-specific code.
extension LibraryView {
    private func mockDelete(withID id: PersistentIdentifier) {
        store.mockDeleteEntry(withId: id)
    }
}

#Preview {
    @Previewable let store = LibraryStore(dataProvider: .default)
    LibraryView(store: store)
}
