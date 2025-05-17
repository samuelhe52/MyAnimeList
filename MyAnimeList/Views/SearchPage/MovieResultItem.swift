//
//  MovieResultItem.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/11.
//

import SwiftUI

struct MovieResultItem: View {
    @Environment(SearchService.self) var service
    let movie: BasicInfo
    
    var body: some View {
        HStack {
            PosterView(url: movie.posterURL)
                .frame(width: 60, height: 90)
            VStack(alignment: .leading) {
                HStack {
                    Text(movie.name)
                        .bold()
                        .lineLimit(1)
                    Spacer()
                    ActionToggle(on: { service.register(movie) },
                                 off: { service.unregister(movie) },
                                 label: { Image(systemName: "checkmark") })
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                }
                if let date = movie.onAirDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .padding(.bottom, 1)
                }
                Text(movie.overview ?? "No overview available")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .lineLimit(3)
            }
        }
    }
}

