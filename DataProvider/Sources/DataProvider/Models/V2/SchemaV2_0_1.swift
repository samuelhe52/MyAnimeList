//
//  SchemaV2_0_1.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/5.
//

import Foundation
import SwiftData

public enum SchemaV2_0_1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 0, 1)
    }
    
    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
