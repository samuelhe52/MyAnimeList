//
//  AnimeEntryListRow.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/10/5.
//

import DataProvider
import Kingfisher
import SwiftUI

struct AnimeEntryListRow: View {
    var entry: AnimeEntry

    var body: some View {
        HStack {
            KFImageView(
                url: entry.posterURL,
                targetWidth: 240,
                diskCacheExpiration: .longTerm)
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 6))
                .frame(width: 80, height: 120)
            info(entry: entry)
        }
    }

    @ViewBuilder
    private func info(entry: AnimeEntry) -> some View {
        VStack(alignment: .leading) {
            Text(entry.displayName)
                .bold()
                .lineLimit(1)
            HStack {
                if let seasonNumber = entry.seasonNumber {
                    Text("Season \(seasonNumber)")
                }
                if let date = entry.onAirDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .font(.caption)
            .padding(.bottom, 1)
            Text(entry.displayOverview ?? "No overview available")
                .font(.caption2)
                .foregroundStyle(.gray)
                .lineLimit(5)
        }
    }
}
