//
//  SchemaV2_2_1.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/12.
//

import Foundation
import SwiftData

public enum SchemaV2_2_1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 2, 1)
    }

    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
