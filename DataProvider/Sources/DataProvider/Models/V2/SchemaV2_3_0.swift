//
//  SchemaV2_3_0.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/6/12.
//

import Foundation
import SwiftData

public enum SchemaV2_3_0: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 3, 0)
    }
    
    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
