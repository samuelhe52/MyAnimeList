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
            scrolledIDSubject.send(scrolledID)
        }
    }

    let scrolledIDSubject = PassthroughSubject<Int?, Never>()
    private let writer: DebouncedIntUserDefaultsWriter

    init() {
        let persistedScrollPosition = UserDefaults.standard.integer(forKey: "persistedScrolledID")
        self.scrolledID = persistedScrollPosition
        self.writer = DebouncedIntUserDefaultsWriter(publisher: scrolledIDSubject.eraseToAnyPublisher(),
                                                     forKey: "persistedScrolledID")
    }
}
