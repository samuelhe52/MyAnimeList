//
//  SchemaV2_1_0.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/10.
//

import Foundation
import SwiftData

enum SchemaV2_1_0: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(2, 1, 0)
    }
    
    static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
