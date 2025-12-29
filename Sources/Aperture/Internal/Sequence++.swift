//
//  Sequence++.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import Foundation

extension Sequence {
    @_spi(Internal)
    public func first<T>(
        byUnwrapping transform: @escaping (Element) throws -> T?
    ) rethrows -> T? {
        try self.lazy.compactMap(transform).first
    }
}
