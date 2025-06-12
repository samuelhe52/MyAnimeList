//
//  SchemaV2.swift
//  DataProvider
//
//  Created by Samuel He on 2025/4/12.
//

import Foundation
import SwiftData

public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 0, 0)
    }
    
    public static var models: [any PersistentModel.Type] {
        [AnimeEntry.self]
    }
}
