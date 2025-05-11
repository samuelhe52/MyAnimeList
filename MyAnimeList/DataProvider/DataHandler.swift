//
//  DataHandler.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/4/6.
//

import Foundation
import SwiftData

@ModelActor
final actor DataHandler {
    @discardableResult
    func newEntry(_ entry: AnimeEntry) throws -> PersistentIdentifier {
        modelContext.insert(entry)
        try modelContext.save()
        return entry.persistentModelID
    }
    
    func updateEntry(id: PersistentIdentifier, entry: AnimeEntry) throws {
        guard let existing = self[id, as: AnimeEntry.self] else { return }
        existing.update(from: entry)
        try modelContext.save()
    }
    
    func updateEntry(id: PersistentIdentifier, info: BasicInfo) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.update(from: info)
        try modelContext.save()
    }
    
    func markAsUnwatched(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.dateStarted = nil
        entry.dateFinished = nil
        try modelContext.save()
    }
    
    func markAsWatching(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.dateStarted = .now
        entry.dateFinished = nil
        try modelContext.save()
    }
    
    func markAsWatched(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        guard entry.dateStarted != nil else { return }
        entry.dateFinished = .now
        try modelContext.save()
    }
    
    func favorite(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.favorite = true
        try modelContext.save()
    }
    
    func unFavorite(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        entry.favorite = false
        try modelContext.save()
    }
    
    func deleteEntry(id: PersistentIdentifier) throws {
        guard let entry = self[id, as: AnimeEntry.self] else { return }
        modelContext.delete(entry)
        try modelContext.save()
    }
    
    func deleteAllEntries() throws {
        let descriptor = FetchDescriptor<AnimeEntry>()
        let allEntries = try modelContext.fetch(descriptor)
        for entry in allEntries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }
}
