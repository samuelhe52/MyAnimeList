//
//  AnimeTypeIndicator.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/11/25.
//

import SwiftUI
import DataProvider

struct AnimeTypeIndicator: View {
    var type: AnimeType
    var padding: CGFloat = 5
    
    var description: LocalizedStringKey {
        switch type {
        case .movie: return "Movie"
        case .series: return "TV Series"
        case .season(let seasonNumber, _): return "Season \(seasonNumber)"
        }
    }
    
    var body: some View {
        Text(description)
            .padding(padding)
            .background(in: .buttonBorder)
            .backgroundStyle(.regularMaterial)
    }
}
