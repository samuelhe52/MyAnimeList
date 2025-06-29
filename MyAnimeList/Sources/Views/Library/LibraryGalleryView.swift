//
//  LibraryGalleryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/25.
//

import SwiftUI
import Foundation
import DataProvider
import AlertToast

struct LibraryGalleryView: View {
    let store: LibraryStore
    @Binding var scrolledID: Int?
    
    var body: some View {
        GeometryReader { geometry in
            let isHorizontal = geometry.size.width < geometry.size.height
            if !store.libraryOnDisplay.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(store.libraryOnDisplay, id: \.tmdbID) { entry in
                            AnimeEntryCardWrapper(entry: entry, delete: { store.deleteEntry($0) })
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

fileprivate struct AnimeEntryCardWrapper: View {
    var entry: AnimeEntry
    let delete: (AnimeEntry) -> Void
    
    @State private var triggerDeleteHaptic: Bool = false
    @State private var showDeleteToast: Bool = false
    @State private var isEditing: Bool = false
    @State private var isSwitchingPoster: Bool = false
    
    var body: some View {
        AnimeEntryCard(entry: entry)
            .onTapGesture {
                showDeleteToast = false
            }
            .onTapGesture(count: 2) {
                isEditing = true
            }
            .toast(isPresenting: $showDeleteToast, duration: 3, alert: {
                AlertToast(displayMode: .alert, type: .regular,
                           titleResource: "Delete Anime?",
                           subTitleResource: "Tap me to confirm.")
            }, onTap: {
                delete(entry)
                triggerDeleteHaptic.toggle()
            })
            .contextMenu {
                contextMenu(entry: entry)
            }
            .sensoryFeedback(.success, trigger: triggerDeleteHaptic)
            .sheet(isPresented: $isEditing) {
                NavigationStack {
                    AnimeEntryEditor(entry: entry)
                }
            }
            .sheet(isPresented: $isSwitchingPoster) {
                NavigationStack {
                    PosterSelectionView(entry: entry)
                        .navigationTitle("Pick a poster")
                }
            }
    }
    
    @ViewBuilder
    func contextMenu(entry: AnimeEntry) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            showDeleteToast = true
        }
        Button {
            isSwitchingPoster = true
        } label: {
            Label("Switch Poster", systemImage: "photo")
        }
        Button("Poster URL", systemImage: "document.on.clipboard") {
            UIPasteboard.general.string = entry.posterURL?.absoluteString ?? ""
            ToastCenter.global.copied = true
        }
        Button("Edit", systemImage: "pencil") {
            isEditing = true
        }
    }
}

// This is where we place debug-specific code.
extension LibraryGalleryView {
    private func mockDelete(entry: AnimeEntry) {
        store.mockDeleteEntry(entry)
    }
}
