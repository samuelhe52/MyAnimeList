//
//  MyAnimeListTests.swift
//  MyAnimeListTests
//
//  Created by Samuel He on 2024/12/8.
//

import Testing
@testable import MyAnimeList

struct MyAnimeListTests {

    @Test func example() async throws {
        let store = CollectionStore()
        try await store.updateInfos()
        print(store.collection[0])
    }

}
