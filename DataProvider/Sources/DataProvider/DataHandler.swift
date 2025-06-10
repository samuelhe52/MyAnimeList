//
//  DataHandler.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/6.
//

import Foundation
import SwiftData

@ModelActor
public final actor DataHandler {
    /// Creates a new anime entry in the database.
    /// - Parameter entry: The anime entry to create.
    /// - Returns: The persistent identifier of the newly created entry.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    public func newEntry(_ entry: AnimeEntry) throws -> PersistentIdentifier {
        // Ensure uniqueness of entries
        guard self[entry.id, as: AnimeEntry.self] == nil else { return entry.id }
        modelContext.insert(entry)
        try modelContext.save()
        return entry.persistentModelID
    }
    
    /// Updates an existing anime entry with new data.
    /// - Parameters:
    ///   - id: The persistent identifier of the entry to update.
    ///   - entry: The anime entry containing updated data.
    /// - Throws: An error if the save operation fails.
    public func updateEntry(id: PersistentIdentifier, entry: AnimeEntry) throws {
        guard let existing = self[id, as: AnimeEntry.self] else { return }
        existing.update(from: entry)
        try modelContext.save()
    }
    
    /// Updates an existing anime entry using a closure.
    /// - Parameters:
    ///   - id: The persistent identifier of the entry to update.
    ///   - action: A closure that modifies the existing entry.
    /// - Throws: An error if the save operation fails or the closure throws.
    public func updateEntry(id: PersistentIdentifier, _ action: (AnimeEntry) throws -> Void) throws {
        guard let existing = self[id, as: AnimeEntry.self] else { return }
        try action(existing)
        try modelContext.save()
    }
    
    /// Marks an anime entry as unwatched by clearing watch dates.
    /// - Parameter id: The persistent identifier of the entry to update.
    /// - Throws: An error if the save operation fails.
    public func markAsUnwatched(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.dateStarted = nil
        entry.dateFinished = nil
        try modelContext.save()
    }
    
    /// Marks an anime entry as currently watching by setting the start date to now.
    /// - Parameter id: The persistent identifier of the entry to update.
    /// - Throws: An error if the save operation fails.
    public func markAsWatching(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.dateStarted = .now
        entry.dateFinished = nil
        try modelContext.save()
    }
    
    /// Marks an anime entry as watched by setting the finish date to now.
    /// - Parameter id: The persistent identifier of the entry to update.
    /// - Throws: An error if the save operation fails.
    /// - Note: This method assumes that the entry has already been marked as currently watching. If it has not, the method will do nothing.
    public func markAsWatched(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        guard entry.dateStarted != nil else { return }
        entry.dateFinished = .now
        try modelContext.save()
    }
    
    /// Marks an anime entry as a favorite.
    /// - Parameter id: The persistent identifier of the entry to update.
    /// - Throws: An error if the save operation fails.
    public func favorite(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.favorite = true
        try modelContext.save()
    }
    
    /// Unmarks an anime entry as a favorite.
    /// - Parameter id: The persistent identifier of the entry to update.
    /// - Throws: An error if the save operation fails.
    public func unFavorite(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.favorite = false
        try modelContext.save()
    }
    
    /// Deletes a specific anime entry.
    /// - Parameter id: The persistent identifier of the entry to delete.
    /// - Throws: An error if the save operation fails.
    public func deleteEntry(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        modelContext.delete(entry)
        try modelContext.save()
    }
    
    /// Deletes all anime entries from the database.
    /// - Throws: An error if the save operation fails.
    public func deleteAllEntries() throws {
        let descriptor = FetchDescriptor<AnimeEntry>()
        let allEntries = try modelContext.fetch(descriptor)
        for entry in allEntries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }
}
