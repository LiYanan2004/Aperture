//
//  Observers.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import Foundation
import Combine

@_spi(Internal)
@propertyWrapper
public struct Cancellables: Equatable, Sendable {
    private final class _Storage: Equatable, @unchecked /* NSLock */ Sendable {
        private let lock = NSLock()
        private var _cancellables: Set<AnyCancellable> = []

        var cancellables: Set<AnyCancellable> {
            get {
                lock.lock()
                defer { lock.unlock() }
                return _cancellables
            }
            set {
                lock.lock()
                _cancellables = newValue
                lock.unlock()
            }
        }
        
        static func == (lhs: Cancellables._Storage, rhs: Cancellables._Storage) -> Bool {
            lhs.cancellables == rhs.cancellables
        }
    }
    
    private let _storage: _Storage = .init()
    
    @_spi(Internal)
    public init(wrappedValue: Set<AnyCancellable> = []) {
        self.wrappedValue = wrappedValue
    }
    
    public var wrappedValue: Set<AnyCancellable> {
        get { _storage.cancellables }
        nonmutating set { _storage.cancellables = newValue }
    }
    
    nonisolated public var projectedValue: Self {
        self
    }
    
    public func cancelAll() {
        _storage.cancellables.forEach { $0.cancel() }
        _storage.cancellables = []
    }
}
