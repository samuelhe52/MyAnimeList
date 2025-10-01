//
//  UserEntryInfo.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/7/15.
//

import Foundation

/// Stores user-specific information about an entry.
public struct UserEntryInfo: Equatable, Codable {
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

    public init(from entry: AnimeEntry) {
        self.watchStatus = entry.watchStatus
        self.dateStarted = entry.dateStarted
        self.dateFinished = entry.dateFinished
        self.favorite = entry.favorite
        self.notes = entry.notes
        self.usingCustomPoster = entry.usingCustomPoster
    }
    
    /// Whether this user info is "empty", i.e. has no meaningful user data.
    public var isEmpty: Bool {
        return watchStatus == .planToWatch &&
        dateStarted == nil &&
        dateFinished == nil &&
        favorite == false &&
        notes.isEmpty &&
        usingCustomPoster == false
    }
}

extension AnimeEntry.WatchStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .planToWatch: return "Plan to Watch"
        case .watching: return "Watching"
        case .watched: return "Watched"
        }
    }
}

extension UserEntryInfo: CustomStringConvertible {
    public var description: String {
        """
        Status: \(watchStatus)
        Started: \(dateStarted?.description ?? "N/A")
        Finished: \(dateFinished?.description ?? "N/A")
        Favorite: \(favorite)
        Notes: \(notes)
        Custom Poster: \(usingCustomPoster)
        """
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
