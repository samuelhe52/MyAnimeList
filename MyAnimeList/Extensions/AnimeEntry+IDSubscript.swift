//
//  AnimeEntry+IDSubscript.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/19.
//

import Foundation

extension Collection where Element == AnimeEntry {
    subscript(id: Int) -> AnimeEntry? {
        guard id != 0 else { return nil }
        return self.first { $0.tmdbID == id }
    }
}
