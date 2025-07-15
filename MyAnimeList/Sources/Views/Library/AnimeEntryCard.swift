//
//  AnimeEntryCard.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/23.
//

import SwiftUI
import DataProvider
import Kingfisher
import AlertToast
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "AnimeEntryCard")

struct AnimeEntryCard: View {
    var entry: AnimeEntry
    @State private var imageLoaded: Bool = false
    var imageMissing: Bool { entry.posterURL == nil }
    
    var body: some View {
        PosterView(url: entry.posterURL, diskCacheExpiration: .longTerm, imageLoaded: $imageLoaded)
            .scaledToFit()
            .clipShape(.rect(cornerRadius: 10))
            .overlay(alignment: .bottomTrailing) {
                AnimeTypeIndicator(type: entry.type)
                    .opacity(imageLoaded ? 1 : 0)
                    .font(.footnote)
            }
            .padding()
    }
}

#Preview {
    AnimeEntryCard(entry: .template())
}
