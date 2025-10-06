//
//  SchemaV2_2_0.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/10.
//

import Foundation
import SwiftData

public enum SchemaV2_2_0: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 2, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
