//
//  ScrollState.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/4.
//

import Combine
import Foundation

@Observable @MainActor
class ScrollState {
    var scrolledID: Int? {
        didSet {
            writer.updateValue(scrolledID)
        }
    }

    @ObservationIgnored private let writer: DebouncedIntUserDefaultsWriter

    init() {
        let persistedScrollPosition = UserDefaults.standard.integer(forKey: .persistedScrolledID)
        self.scrolledID = persistedScrollPosition
        self.writer = DebouncedIntUserDefaultsWriter(forKey: .persistedScrolledID)
    }
}
