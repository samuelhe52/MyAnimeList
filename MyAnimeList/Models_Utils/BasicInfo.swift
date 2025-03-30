//
//  BasicInfo.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation

struct BasicInfo {
    var name: String
    var overview: String?
    var posterURL: URL?
    var backdropURL: URL?
    var tmdbId: Int
    var linkToDetails: URL?
    
    var entryType: EntryType
}
