//
//  BackupManager.swift
//  MyAnimeList
//
//  Created by Samuel He on 8/22/25.
//

import Foundation
import UniformTypeIdentifiers
import ZIPFoundation
import DataProvider
import SwiftData

extension UTType {
    static let mallib = UTType(exportedAs: "com.samuelhe.myanimelist.mallib")
}

// MARK: - Backup and Restore Error Enum
enum BackupError: LocalizedError {
    case fileCreationFailed
    case backupDirectoryCreationFailed
    case userDefaultsSerializationFailed
    case swiftDataStoreNotFound
    case archiveCreationFailed
    case restoreDirectoryCreationFailed
    case archiveExtractionFailed
    case backupFileNotFound
    case restoreFailed(reason: String)
    case schemaVersionIncompatible(highest: Schema.Version, found: Schema.Version)

    var errorDescription: String? {
        switch self {
        case .fileCreationFailed:
            return "Failed to create the backup file."
        case .backupDirectoryCreationFailed:
            return "Could not create the temporary backup directory."
        case .userDefaultsSerializationFailed:
            return "Failed to serialize user settings."
        case .swiftDataStoreNotFound:
            return "Could not locate the SwiftData store files."
        case .archiveCreationFailed:
            return "Failed to create the ZIP archive for the backup."
        case .restoreDirectoryCreationFailed:
            return "Could not create the temporary restore directory."
        case .archiveExtractionFailed:
            return "Failed to extract the backup archive."
        case .backupFileNotFound:
            return "The backup file could not be found in the archive."
        case .restoreFailed(let reason):
            return "Restore failed: \(reason)"
        case .schemaVersionIncompatible(let highest, let found):
            return "Incompatible schema version. The highest supported version is \(highest), but found \(found). Please update the app."
        }
    }
}

// MARK: - Backup Manager
@MainActor
class BackupManager {
    let dataProvider: DataProvider
    
    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    // MARK: - Properties
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    private let backupFileName = "MyAnimeList_Backup_" + Date().ISO8601Format()
    private let userSettingsFileName = "UserSettings.json"
    private let schemaVersionFileName = "SchemaVersion.txt"

    // MARK: - Public Methods

    /// Creates a backup of the SwiftData store and user settings.
    /// - Returns: The URL of the created backup file.
    /// - Throws: A `BackupError` if the process fails.
    func createBackup() throws -> URL {
        // 1. Create a temporary directory to stage files for backup.
        let backupDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try fileManager.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw BackupError.backupDirectoryCreationFailed
        }

        // 2. Save SwiftData schema version
        let schemaVersion = DataProvider.default.sharedModelContainer.schema.version
        let versionFileURL = backupDirectoryURL.appendingPathComponent(schemaVersionFileName)
        do {
            let schemaVersionJson = try JSONEncoder().encode(schemaVersion)
            try schemaVersionJson.write(to: versionFileURL, options: [.atomic])
        } catch {
            throw BackupError.fileCreationFailed
        }

        // 3. Save user settings to the temporary directory.
        try saveUserSettings(to: backupDirectoryURL)

        // 4. Copy SwiftData store files to the temporary directory.
        try copySwiftDataStore(to: backupDirectoryURL)

        // 5. Create a ZIP archive from the temporary directory.
        let archiveURL = fileManager.temporaryDirectory.appendingPathComponent(backupFileName, conformingTo: .mallib)
        
        // If a file already exists, remove it.
        if fileManager.fileExists(atPath: archiveURL.path()) {
            try fileManager.removeItem(at: archiveURL)
        }

        do {
            try fileManager.zipItem(at: backupDirectoryURL, to: archiveURL)
        } catch {
            throw BackupError.archiveCreationFailed
        }

        // 6. Clean up the temporary backup directory.
        try? fileManager.removeItem(at: backupDirectoryURL)

        return archiveURL
    }
    
    /// Restores the SwiftData store and user settings from a backup file.
    /// - Parameter sourceURL: The URL of the backup file to restore from.
    /// - Throws: A `BackupError` if the process fails.
    /// - Note: This function will likely require you to restart the app to see the changes.
    func restoreBackup(from sourceURL: URL) throws {
        // 1. Create a temporary directory for extraction.
        let restoreDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try fileManager.createDirectory(at: restoreDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw BackupError.restoreDirectoryCreationFailed
        }

        // 2. Extract the archive.
        do {
            try fileManager.unzipItem(at: sourceURL, to: restoreDirectoryURL)
        } catch {
            throw BackupError.archiveExtractionFailed
        }
        
        let restoredFolderName = try fileManager.contentsOfDirectory(atPath: restoreDirectoryURL.path()).first!
        
        let restoredFilesURL = restoreDirectoryURL.appending(path: restoredFolderName, directoryHint: .isDirectory)
        
        // 3. Restore user settings.
        try restoreUserSettings(from: restoredFilesURL)

        // 4. Restore SwiftData store.
        try restoreSwiftDataStore(from: restoredFilesURL)
        
        // 5. Clean up the temporary restore directory.
        try? fileManager.removeItem(at: restoreDirectoryURL)
        
        // 6. Reload ModelContainer for SwiftData
        dataProvider.reloadDataStore()
    }


    // MARK: - Private Helper Methods

    /// Gathers user settings and saves them to a file within the backup package.
    private func saveUserSettings(to directoryURL: URL) throws {
        let settings = String.allPreferenceKeys.reduce(into: [String: Any]()) { (dict, key) in
            dict[key] = userDefaults.value(forKey: key)
        }

        let fileURL = directoryURL.appendingPathComponent(userSettingsFileName)
        do {
            let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
            try data.write(to: fileURL)
        } catch {
            throw BackupError.userDefaultsSerializationFailed
        }
    }

    /// Copies the SwiftData database files to the backup package.
    private func copySwiftDataStore(to directoryURL: URL) throws {
        let storeDirectory = URL.applicationSupportDirectory

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                 // The store files could have extensions like -shm, -wal.
                if fileURL.lastPathComponent.starts(with: "default.store") {
                    let destinationURL = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
                    try fileManager.copyItem(at: fileURL, to: destinationURL)
                }
            }
        } catch {
            throw BackupError.restoreFailed(reason: "Could not copy database files. \(error.localizedDescription)")
        }
    }
    
    /// Restores user settings from a file within the backup package.
    private func restoreUserSettings(from directoryURL: URL) throws {
        let fileURL = directoryURL.appendingPathComponent(userSettingsFileName)
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            throw BackupError.backupFileNotFound
        }

        do {
            let data = try Data(contentsOf: fileURL)
            if let settings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for (key, value) in settings {
                    userDefaults.set(value, forKey: key)
                }
            }
        } catch {
            throw BackupError.restoreFailed(reason: "Could not deserialize user settings. \(error.localizedDescription)")
        }
    }

    /// Replaces the current SwiftData store with the one from the backup package.
    private func restoreSwiftDataStore(from directoryURL: URL) throws {
        let storeDirectory = URL.applicationSupportDirectory

        do {
            // Check schema version compatibility
            let versionFileURL = directoryURL.appendingPathComponent(schemaVersionFileName)
            if fileManager.fileExists(atPath: versionFileURL.path()) { // Only check if file exists, for backward compatibility
                let versionData = try Data(contentsOf: versionFileURL)
                let backupSchemaVersion = try JSONDecoder().decode(Schema.Version.self, from: versionData)
                let currentSchemaVersion = DataProvider.default.sharedModelContainer.schema.version
                guard backupSchemaVersion < currentSchemaVersion else {
                    throw BackupError.schemaVersionIncompatible(highest: currentSchemaVersion, found: backupSchemaVersion)
                }
            }

            // Remove current store files
            let currentFiles = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            for fileURL in currentFiles {
                if fileURL.lastPathComponent.starts(with: "default.store") {
                    try fileManager.removeItem(at: fileURL)
                }
            }

            // Copy backed up files from the backup package
            let backupFiles = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            for fileURL in backupFiles {
                if fileURL.lastPathComponent.starts(with: "default.store") {
                    let destinationURL = storeDirectory.appendingPathComponent(fileURL.lastPathComponent)
                    try fileManager.copyItem(at: fileURL, to: destinationURL)
                }
            }
        } catch {
            throw BackupError.restoreFailed(reason: "Could not replace the database files. \(error.localizedDescription)")
        }
    }
}
