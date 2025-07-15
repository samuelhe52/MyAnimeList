//
//  UserEntryInfo.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/7/15.
//

import Foundation

/// Stores user-specific information about an entry.
public struct UserEntryInfo: Codable {
    /// User's watch status for this entry.
    public var watchStatus: AnimeEntry.WatchStatus
    
    /// Date started watching.
    public var dateStarted: Date?
    
    /// Date marked finished.
    public var dateFinished: Date?
    
    /// Whether the entry is marked as favorite.
    public var favorite: Bool

    /// Notes for this entry.
    public var notes: String
    
    /// Whether the entry is using a custom poster image.
    public var usingCustomPoster: Bool
    
    private init(watchStatus: AnimeEntry.WatchStatus, dateStarted: Date? = nil, dateFinished: Date? = nil, favorite: Bool, notes: String, usingCustomPoster: Bool) {
        self.watchStatus = watchStatus
        self.dateStarted = dateStarted
        self.dateFinished = dateFinished
        self.favorite = favorite
        self.notes = notes
        self.usingCustomPoster = usingCustomPoster
    }

    public init(fromEntry entry: AnimeEntry) {
        self.watchStatus = entry.watchStatus
        self.dateStarted = entry.dateStarted
        self.dateFinished = entry.dateFinished
        self.favorite = entry.favorite
        self.notes = entry.notes
        self.usingCustomPoster = entry.usingCustomPoster
    }
}

extension AnimeEntry {
    public func updateUserInfo(from userInfo: UserEntryInfo) {
        watchStatus = userInfo.watchStatus
        dateStarted = userInfo.dateStarted
        dateFinished = userInfo.dateFinished
        favorite = userInfo.favorite
        notes = userInfo.notes
        usingCustomPoster = userInfo.usingCustomPoster
    }
}
