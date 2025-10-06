//
//  SchemaV2_4_0.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/10/05.
//

import Foundation
import SwiftData

public enum SchemaV2_4_0: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 4, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
