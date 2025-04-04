//
//  AnimeEntryCard.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/23.
//

import SwiftUI
import Kingfisher

struct AnimeEntryCard: View {
    var entry: AnimeEntry?
    
    var body: some View {
        image
    }
    
    @ViewBuilder
    private var image: some View {
        if let url = entry?.posterURL {
            KFImage(url)
                .resizable()
                .cacheOriginalImage()
                .cancelOnDisappear(true)
                .fade(duration: 0.5)
                .clipShape(.rect(cornerRadius: 10))
                .scaledToFit()
                .padding()
        }
    }
}

#Preview {
    @Previewable let store: LibraryStore = .init()
    AnimeEntryCard(entry: store.library.first)
        .task {
            try? await store.updateInfos()
        }
}
