//
//  LibraryGalleryView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/25.
//

import AlertToast
import DataProvider
import Foundation
import SwiftUI

struct LibraryGalleryView: View {
    let store: LibraryStore
    @Environment(LibraryEntryInteractionState.self) var interaction
    @Binding var scrolledID: Int?

    var body: some View {
        if !store.libraryOnDisplay.isEmpty {
            libraryContent
        } else {
            Color.clear
                .overlay {
                    Text("The library is empty.")
                }
        }
    }

    private var libraryContent: some View {
        GeometryReader { geometry in
            let isHorizontal = geometry.size.width < geometry.size.height
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(store.libraryOnDisplay, id: \.tmdbID) { entry in
                        AnimeEntryCardWrapper(entry: entry, delete: deleteEntry)
                            .containerRelativeFrame(isHorizontal ? .horizontal : .vertical)
                            .transition(.opacity)
                            .onScrollVisibilityChange { _ in }
                    }
                }.scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private func deleteEntry(_ entry: AnimeEntry) {
        interaction.setScrolledIDBeforeDeletion(for: entry, in: store, scrolledID: $scrolledID)
        store.deleteEntry(entry)
    }
}

fileprivate struct AnimeEntryCardWrapper: View {
    var entry: AnimeEntry
    let delete: (AnimeEntry) -> Void

    @State private var triggerDeleteHaptic: Bool = false
    @State private var showDeleteToast: Bool = false
    @State private var isEditing: Bool = false
    @State private var isSwitchingPoster: Bool = false
    @State private var isSharingAnime: Bool = false
    @State private var imageLoaded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if imageLoaded {
                AnimeEntryDates(entry: entry)
            }
            AnimeEntryCard(entry: entry, imageLoaded: $imageLoaded)
                .contextMenu {
                    contextMenu(for: entry)
                }
        }
        .onTapGesture {
            showDeleteToast = false
        }
        .onTapGesture(count: 2) {
            isEditing = true
        }
        .toast(
            isPresenting: $showDeleteToast, duration: 3,
            alert: {
                AlertToast(
                    displayMode: .alert, type: .regular,
                    titleResource: "Delete Anime?",
                    subTitleResource: "Tap me to confirm.")
            },
            onTap: {
                delete(entry)
                triggerDeleteHaptic.toggle()
            }
        )
        .sensoryFeedback(.success, trigger: triggerDeleteHaptic)
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                AnimeEntryEditor(entry: entry)
            }
        }
        .sheet(isPresented: $isSwitchingPoster) {
            NavigationStack {
                PosterSelectionView(tmdbID: entry.tmdbID, type: entry.type) { url in
                    entry.posterURL = url
                    entry.usingCustomPoster = true
                }
                .navigationTitle("Pick a poster")
            }
        }
        .sheet(isPresented: $isSharingAnime) {
            AnimeSharingSheet(entry: entry)
        }
    }

    @ViewBuilder
    func contextMenu(for entry: AnimeEntry) -> some View {
        ControlGroup {
            Button {
                isSharingAnime = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button("Edit", systemImage: "pencil") {
                isEditing = true
            }
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
        Button("Delete", systemImage: "trash", role: .destructive) {
            showDeleteToast = true
        }
    }
}

// This is where we place debug-specific code.
extension LibraryGalleryView {
    private func mockDelete(entry: AnimeEntry) {
        store.mockDeleteEntry(entry)
    }
}
