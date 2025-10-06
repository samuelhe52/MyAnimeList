//
//  Schema.swift
//  DataProvider
//
//  Created by Samuel He on 2025/4/5.
//

import Foundation
import SwiftData

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
