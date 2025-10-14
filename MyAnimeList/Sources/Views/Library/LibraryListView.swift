//
//  LibraryListView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/29.
//

import DataProvider
import SwiftUI

struct LibraryListView: View {
    let store: LibraryStore
    @Environment(LibraryEntryInteractionState.self) var interaction
    @Environment(\.toggleFavorite) var toggleFavorite

    @Binding var scrolledID: Int?
    @Binding var highlightedEntryID: Int?

    var body: some View {
        ScrollViewReader { proxy in
            List(store.libraryOnDisplay, id: \.tmdbID) { entry in
                AnimeEntryListRow(entry: entry)
                    .highlightEffect(
                        showHighlight: interaction.highlightBinding(
                            for: entry,
                            highlightedEntryID: $highlightedEntryID
                        ),
                        delay: 0.2
                    )
                    .onTapGesture { scrolledID = entry.tmdbID }
                    .contextMenu {
                        interaction.contextMenu(
                            for: entry,
                            store: store,
                            scrolledID: $scrolledID,
                            toggleFavorite: toggleFavorite
                        )
                     } preview: {
                        EntryPreview(entry: entry)
                            .onAppear { scrolledID = entry.tmdbID }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", systemImage: "trash") {
                            interaction.prepareDeletion(
                                for: entry,
                                store: store,
                                scrolledID: $scrolledID
                            )
                        }
                        .tint(.red)
                    }
                    .swipeActions(edge: .leading) {
                        Button("Edit", systemImage: "pencil") {
                            interaction.setEditingEntry(entry)
                        }
                        .tint(.blue)
                    }
                    .onTapGesture(count: 2) { interaction.setEditingEntry(entry) }
            }
            .animation(.default, value: store.sortReversed)
            .animation(.default, value: store.sortStrategy)
            .animation(.default, value: store.filters)
            .onChange(of: scrolledID, initial: true) {
                if let scrolledID {
                    proxy.scrollTo(scrolledID)
                }
            }
        }
        .libraryEntryInteractionOverlays(state: interaction, store: store)
    }
}
