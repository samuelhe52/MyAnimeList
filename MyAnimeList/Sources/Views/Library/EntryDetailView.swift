//
//  EntryDetailView.swift
//  MyAnimeList
//
//  Created by Samuel He on 8/1/25.
//

import DataProvider
import SwiftUI

struct EntryDetailView: View {
    var entry: AnimeEntry

    var body: some View {
        ZStack {
            KFImageView(url: entry.backdropURL, diskCacheExpiration: .longTerm)
                .aspectRatio(contentMode: .fit)
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    EntryDetailView(entry: .frieren)
}
