//
//  SchemaV2_3_1.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/27.
//

import Foundation
import SwiftData

public enum SchemaV2_3_1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 3, 1)
    }

    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
