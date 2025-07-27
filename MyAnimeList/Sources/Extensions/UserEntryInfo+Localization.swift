//
//  UserEntryInfo+Localization.swift
//  MyAnimeList
//
//  Created by Samuel He on 7/19/25.
//

import Foundation
import DataProvider
import SwiftUI

extension AnimeEntry.WatchStatus: @retroactive CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .planToWatch: return "Plan to Watch"
        case .watching: return "Watching"
        case .watched: return "Watched"
        }
    }
}

extension UserEntryInfo: @retroactive CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        """
        Status: \(watchStatus)
        Started: \(dateStarted?.description ?? "N/A")
        Finished: \(dateFinished?.description ?? "N/A")
        Favorite: \(favorite ? "Yes" : "No")
        Notes: \(notes)
        Custom Poster: \(usingCustomPoster ? "Yes" : "No")
        """
    }
}
