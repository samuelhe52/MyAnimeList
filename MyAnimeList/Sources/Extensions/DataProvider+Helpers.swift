//
//  AnimeEntry+Helpers.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/24.
//

import DataProvider
import SwiftData

extension AnimeEntry {
    /// Creates a new AnimeEntry instance from BasicInfo.
    ///
    /// - Parameter info: The BasicInfo containing the anime details.
    convenience init(fromInfo info: BasicInfo) {
        self.init(name: info.name,
                  overview: info.overview,
                  onAirDate: info.onAirDate,
                  type: info.type,
                  linkToDetails: info.linkToDetails,
                  posterURL: info.posterURL,
                  backdropURL: info.backdropURL,
                  tmdbID: info.tmdbID,
                  dateSaved: .now)
    }
    
    /// Updates the anime entry with new information from BasicInfo.
    ///
    /// - Parameter info: The BasicInfo containing updated anime details.
    /// - Note: Only updates properties that have non-nil values in the info parameter.
    func update(from info: BasicInfo) {
        name = info.name
        overview = info.overview ?? self.overview
        linkToDetails = info.linkToDetails ?? self.linkToDetails
        posterURL = info.posterURL ?? self.posterURL
        backdropURL = info.backdropURL ?? self.backdropURL
        onAirDate = info.onAirDate ?? self.onAirDate
        type = info.type
        tmdbID = info.tmdbID
    }
    
    /// Converts the AnimeEntry to BasicInfo.
    var basicInfo: BasicInfo {
        BasicInfo(name: name,
                  overview: overview,
                  posterURL: posterURL,
                  backdropURL: backdropURL,
                  tmdbID: tmdbID,
                  onAirDate: onAirDate,
                  linkToDetails: linkToDetails,
                  type: type)
    }
}

extension DataHandler {
    /// Updates an existing anime entry with a `BasicInfo`.
    ///
    /// - Parameters:
    ///   - id: The persistent identifier of the entry to update
    ///   - info: The BasicInfo containing updated anime details
    /// - Throws: Errors from the underlying data store operations
    func updateEntry(id: PersistentIdentifier, info: BasicInfo) throws {
        try updateEntry(id: id) { entry in
            entry.update(from: info)
        }
    }
}
