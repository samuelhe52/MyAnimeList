//
//  DataProvider.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/5.
//

import Foundation
import SwiftData

typealias CurrentSchema = SchemaV1
typealias AnimeEntry = SchemaV1.AnimeEntry

final class DataProvider: Sendable {
    static let shared = DataProvider()
    static let forPreview = DataProvider(inMemory: true)
    
    let sharedModelContainer: ModelContainer
    let dataHandler: DataHandler
    
    init(inMemory: Bool = false) {
        // Data migration happens here
        self.sharedModelContainer = {
            let schema = Schema(CurrentSchema.models)
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
            
            do {
                return try ModelContainer(for: schema, configurations: modelConfiguration)
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
        dataHandler = .init(modelContainer: sharedModelContainer)
    }
}
