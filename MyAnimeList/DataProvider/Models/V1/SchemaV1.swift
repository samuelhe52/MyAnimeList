//
//  Schema.swift
//  DataProvider
//
//  Created by Samuel He on 2025/4/5.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
