//
//  AnimeEntryCard.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/23.
//

import AlertToast
import DataProvider
import Kingfisher
import SwiftUI
import os

fileprivate let logger = Logger(subsystem: .bundleIdentifier, category: "AnimeEntryCard")

struct AnimeEntryCard: View {
    var entry: AnimeEntry
    @Binding var imageLoaded: Bool
    var imageMissing: Bool { entry.posterURL == nil }

    var body: some View {
        KFImageView(
            url: entry.posterURL, diskCacheExpiration: .longTerm, imageLoaded: $imageLoaded
        )
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
    AnimeEntryCard(entry: .template(), imageLoaded: .constant(true))
}
