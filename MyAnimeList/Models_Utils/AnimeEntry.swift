//
//  AnimeEntry.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import TMDb

protocol AnimeEntry: Identifiable, Codable {
    var name: String { get set }
    var overview: String? { get set }
    var onAirDate: Date? { get set }
    
    /// Link ot the homepage of the anime.
    var linkToDetails: URL? { get set }
    
    var posterURL: URL? { get set }
    var backdropURL: URL? { get set }
    
    /// The unique TMDB id for this entry.
    var id: Int { get set }
    
    /// Date added to library.
    var dateAdded: Date? { get set }
    
    /// Date marked finished.
    var dateFinished: Date? { get set }
    
    mutating func updateInfo(fromInfo info: BasicInfo)
    func fetchMetadata(fetcher: InfoFetcher) async throws -> BasicInfo
}
