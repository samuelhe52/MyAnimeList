//
//  EnvironmentValues+Extensions.swift
//  DataProvider
//
//  Created by Samuel He on 2025/6/12.
//

import SwiftUI

extension EnvironmentValues {
    @Entry public var createDataHandler: @Sendable () async -> DataHandler? = { nil }
}
