//
//  EntryContextMenuPreview.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/19/25.
//

import DataProvider
import SwiftUI

struct EntryContextMenuPreview: View {
    var entry: AnimeEntry
    var showTypeIndicator: Bool = true

    var body: some View {
        KFImageView(url: entry.posterURL, diskCacheExpiration: .longTerm)
            .scaledToFit()
            .overlay(alignment: .bottomTrailing) {
                if showTypeIndicator {
                    AnimeTypeIndicator(type: entry.type)
                        .offset(x: -3, y: -3)
                        .font(.footnote)
                }
            }
    }
}
