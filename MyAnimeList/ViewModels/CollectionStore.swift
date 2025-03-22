//
//  CollectionStore.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/3/22.
//

import Foundation
import SwiftUI

@Observable
class CollectionStore {
    var collection: [AnimeItem] = [.init(name: "koe no katachi", mediaType: .movie)]
    private var infoFetcher: InfoFetcher = .init()
    
    func updateInfos() async throws {
        for index in collection.indices {
            let basicInfo = try await infoFetcher.basicInfo(for: collection[index])
            collection[index].updateInfo(from: basicInfo)
        }
    }
}
