//
//  BasicInfo.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation

struct BasicInfo: Equatable, Identifiable, Hashable {
    var name: String
    var overview: String?
    var posterURL: URL?
    var backdropURL: URL?
    var logoURL: URL?
    var tmdbID: Int
    var onAirDate: Date?
    var linkToDetails: URL?
    
    var type: AnimeType
    
    var id: Int { tmdbID }
}
