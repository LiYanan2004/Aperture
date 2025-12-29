//
//  Logging.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/15.
//

import Foundation
import OSLog

protocol Logging {
    nonisolated var logger: Logger { get }
}

extension Logging {
    nonisolated public var logger: Logger {
        Logger(
            subsystem: "Aperture",
            category: "\(Self.self)"
        )
    }
}
