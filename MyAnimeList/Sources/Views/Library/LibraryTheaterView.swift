//
//  LibraryTheaterView.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/25.
//

import SwiftUI
import Foundation
import DataProvider
import SwiftData

struct LibraryTheaterView: View {
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
                                store.deleteEntry(withID: entry.id)
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
extension LibraryTheaterView {
    private func mockDelete(withID id: PersistentIdentifier) {
        store.mockDeleteEntry(withID: id)
    }
}
