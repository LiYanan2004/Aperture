//
//  ValueObservation.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/6/3.
//

import Foundation
import Combine

@_transparent
@_spi(Internal)
public func withValueObservation<V: NSObject, K>(
    of value: V,
    keyPath: KeyPath<V, K>,
    cancellables: inout Set<AnyCancellable>,
    action: @escaping (K) -> Void
) {
    value
        .publisher(for: keyPath, options: [.initial, .new])
        .share()
        .sink(receiveValue: action)
        .store(in: &cancellables)
}
