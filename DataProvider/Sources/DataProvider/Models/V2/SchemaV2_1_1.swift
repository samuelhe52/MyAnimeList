//
//  SchemaV2_1_1.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/10.
//

import Foundation
import SwiftData

public enum SchemaV2_1_1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 1, 1)
    }
    
    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
