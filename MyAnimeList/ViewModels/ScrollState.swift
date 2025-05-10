//
//  ScrollState.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/4.
//

import Foundation
import Combine

@Observable @MainActor
class ScrollState {
    var scrolledID: Int? {
        didSet {
            writer.updateValue(scrolledID)
        }
    }

    private let writer: DebouncedIntUserDefaultsWriter

    init() {
        let persistedScrollPosition = UserDefaults.standard.integer(forKey: .persistedScrolledID)
        self.scrolledID = persistedScrollPosition
        self.writer = DebouncedIntUserDefaultsWriter(forKey: .persistedScrolledID)
    }
}
