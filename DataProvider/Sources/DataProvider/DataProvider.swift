//
//  DataProvider.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/5.
//

import Foundation
import SwiftData

/// The current schema version used by the data provider.
public typealias CurrentSchema = SchemaV2_4_0

/// The current anime entry type used by the data provider.
public typealias AnimeEntry = CurrentSchema.AnimeEntry

/// A data provider for SwiftData model containers and data operations, stored in MainActor.
@MainActor public final class DataProvider {
    /// The default shared instance of the data provider.
    public static let `default` = DataProvider()

    /// A preview instance of the data provider that uses in-memory storage.
    public static let forPreview = DataProvider(inMemory: true)

    /// The shared model container used for data persistence.
    public private(set) var sharedModelContainer: ModelContainer

    /// The data handler instance for performing data operations.
    public private(set) var dataHandler: DataHandler

    /// Whether this instance's data is stored in memory.
    public let inMemory: Bool

    /// Creates a new data provider instance.
    /// - Parameter inMemory: If true, uses in-memory storage instead of persistent storage.
    /// - Important: This initializer will fatalError if the model container cannot be created.
    ///              This is intentional as the app cannot function without proper data storage.
    public init(inMemory: Bool = false) {
        self.inMemory = inMemory
        // Data migration happens here
        self.sharedModelContainer = {
            let schema = Schema(CurrentSchema.models)
            let modelConfiguration = ModelConfiguration(
                schema: schema, isStoredInMemoryOnly: inMemory)

            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: MigrationPlan.self,
                    configurations: modelConfiguration)
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
        dataHandler = .init(modelContainer: sharedModelContainer)
    }

    /// Tears down the existing model container and re-initializes it from the persistent store.
    ///
    /// This is crucial for applying changes after a restore operation.
    public func reloadDataStore() {
        setupContainer()
    }

    /// Sets up the model container.
    ///
    /// This will fatalError if the container cannot be created.
    private func setupContainer() {
        // Data migration happens here
        do {
            let schema = Schema(CurrentSchema.models)
            let modelConfiguration = ModelConfiguration(
                schema: schema, isStoredInMemoryOnly: inMemory)

            sharedModelContainer = try ModelContainer(
                for: schema,
                migrationPlan: MigrationPlan.self,
                configurations: modelConfiguration)
        } catch {
            fatalError("Could not create or reload ModelContainer: \(error)")
        }
        dataHandler = .init(modelContainer: sharedModelContainer)
    }

    /// Gets all persistent models of a certain type.
    public func getAllModels<T: PersistentModel>(ofType: T.Type) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try sharedModelContainer.mainContext.fetch(descriptor)
    }
}
