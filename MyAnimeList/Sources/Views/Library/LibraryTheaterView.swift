//
//  LibraryTheaterView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/25.
//

import SwiftUI
import Foundation
import DataProvider
import AlertToast

struct LibraryTheaterView: View {
    let store: LibraryStore
    @Binding var scrolledID: Int?
    
    @State private var switchingPosterForEntry: AnimeEntry? = nil
    @State private var editingEntry: AnimeEntry? = nil
    @State private var triggerDeleteHaptic: Bool = false
    @State private var showDeleteToast: Bool = false
    
    @GestureState private var dragUpOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let isHorizontal = geometry.size.width < geometry.size.height
            if !store.libraryOnDisplay.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(store.libraryOnDisplay, id: \.tmdbID) { entry in
                            entryCard(entry: entry)
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
        .sheet(item: $switchingPosterForEntry) { entry in
            NavigationStack {
                PosterSelectionView(entry: entry)
                    .navigationTitle("Pick a poster")
            }
        }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                AnimeEntryEditor(entry: entry)
            }
        }
    }
    
    @ViewBuilder
    func entryCard(entry: AnimeEntry) -> some View {
        AnimeEntryCard(entry: entry)
            .onTapGesture {
                showDeleteToast = false
            }
            .onTapGesture(count: 2) {
                editingEntry = entry
            }
            .toast(isPresenting: $showDeleteToast, duration: 3, alert: {
                AlertToast(displayMode: .alert, type: .regular,
                           titleResource: "Delete Anime?",
                           subTitleResource: "Tap me to confirm.")
            }, onTap: {
                store.deleteEntry(entry)
                triggerDeleteHaptic.toggle()
            })
            .contextMenu {
                contextMenu(entry: entry)
            }
            .sensoryFeedback(.success, trigger: triggerDeleteHaptic)
    }
    
    @ViewBuilder
    func contextMenu(entry: AnimeEntry) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            showDeleteToast = true
        }
        Button {
            switchingPosterForEntry = entry
        } label: {
            Label("Switch Poster", systemImage: "photo")
        }
        Button("Poster URL", systemImage: "document.on.clipboard") {
            UIPasteboard.general.string = entry.posterURL?.absoluteString ?? ""
            ToastCenter.global.copied = true
        }
        Button("Edit", systemImage: "pencil") {
            editingEntry = entry
        }
    }
}

// This is where we place debug-specific code.
extension LibraryTheaterView {
    private func mockDelete(entry: AnimeEntry) {
        store.mockDeleteEntry(entry)
    }
}
