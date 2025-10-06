//
//  SchemaV2_3_2.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/28.
//

import Foundation
import SwiftData

public enum SchemaV2_3_2: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 3, 2)
    }

    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
