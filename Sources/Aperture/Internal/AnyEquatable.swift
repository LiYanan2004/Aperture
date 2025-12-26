//
//  AnyEquatable.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import Foundation

struct AnyEquatable: Equatable {
    var base: Any
    var _isEqualTo: (_ x: Any, _ y: Any) -> Bool
    
    init<E: Equatable>(_ base: E) {
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
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._isEqualTo(lhs.base, rhs.base)
    }
}

extension Equatable {
    func eraseToAnyEquatable() -> AnyEquatable {
        AnyEquatable(self)
    }
}
