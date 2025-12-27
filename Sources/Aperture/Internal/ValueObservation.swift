//
//  ValueObservation.swift
//  Aperture
//
//  Created by LiYanan2004 on 2025/6/3.
//

import Swift
import Combine
import ObjectiveC
import Observation

func withValueObservation<V: NSObject, K>(
    of value: V,
    keyPath: KeyPath<V, K>,
    cancellables: inout (some RangeReplaceableCollection<AnyCancellable>),
    action: @escaping (K) -> Void
) {
    value
        .publisher(for: keyPath)
        .share()
        .sink(receiveValue: action)
        .store(in: &cancellables)
}

func withValueObservation<V: NSObject, K>(
    of value: V,
    keyPath: KeyPath<V, K>,
    cancellables: inout Set<AnyCancellable>,
    action: @escaping (K) -> Void
) {
    value
        .publisher(for: keyPath)
        .share()
        .sink(receiveValue: action)
        .store(in: &cancellables)
}
