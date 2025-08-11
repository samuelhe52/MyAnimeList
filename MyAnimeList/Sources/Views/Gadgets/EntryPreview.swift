//
//  EntryPreview.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/19/25.
//

import SwiftUI
import DataProvider

struct EntryPreview: View {
    var entry: AnimeEntry
    
    var body: some View {
        KFImageView(url: entry.posterURL, diskCacheExpiration: .longTerm)
            .scaledToFit()
            .overlay(alignment: .bottomTrailing) {
                AnimeTypeIndicator(type: entry.type)
                    .offset(x: -3, y: -3)
                    .font(.footnote)
            }
    }
}
