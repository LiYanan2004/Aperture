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

//@Sendable
//func withValueObservation<O: Observable & Sendable, V: Sendable>(
//    of value: O,
//    keyPath: @Sendable @autoclosure () -> Void
//    action: @escaping @Sendable () -> Void
//) {
//    withObservationTracking {
//        _ = value[keyPath: keyPath]
//    } onChange: {
//        action()
//        // Capture of 'keyPath' with non-Sendable type 'KeyPath<O, V>' in a '@Sendable' closure
//        // Capture of 'value' with non-Sendable type 'O' in a '@Sendable' closure
//        withValueObservation(of: value, keyPath: keyPath, action: action)
//    }
//}
