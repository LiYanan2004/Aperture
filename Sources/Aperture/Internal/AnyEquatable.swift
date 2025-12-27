//
//  AnyEquatable.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import Foundation

@_spi(Internal)
public struct AnyEquatable: Equatable {
    public var base: Any
    @usableFromInline
    var _isEqualTo: (_ x: Any, _ y: Any) -> Bool
    
    @_spi(Internal)
    public init<E: Equatable>(_ base: E) {
        if let base = base as? AnyEquatable {
            self = base
        } else {
            func equate(_ x: Any, _ y: Any) -> Bool {
                assert(!(x is AnyEquatable))
                assert(!(y is AnyEquatable))
                
                guard let x = x as? E, let y = y as? E else {
                    return false
                }
                
                return x == y
            }
            
            self._isEqualTo = equate
            self.base = base
        }
    }
    
    @_transparent
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._isEqualTo(lhs.base, rhs.base)
    }
}

extension Equatable {
    @_spi(Internal)
    public func eraseToAnyEquatable() -> AnyEquatable {
        AnyEquatable(self)
    }
}
