//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST

public struct Fp12: Equatable {
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}

public extension Fp12 {
    init(fp6 first: Fp6, second: Fp6) {
        self.init(storage: .init(fp6: first.storage, second: second.storage))
    }
}
public extension Fp12 {
    func isInGroup() -> Bool {
        storage.isInGroup()
    }
}

internal extension Fp12 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}


internal extension Fp12 {
    final class Storage: Equatable {
        typealias LowLevel = blst_fp12
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fp12.Storage {
    convenience init(fp6 first: Fp6.Storage, second: Fp6.Storage) {
        let lowLevel = first.withUnsafeLowLevelAccess { f in
            second.withUnsafeLowLevelAccess { s in
                blst_fp12(fp6: (f.pointee, s.pointee))
            }
        }
        self.init(lowLevel: lowLevel)
    }
}


internal extension Fp12.Storage {
    static func ==(lhs: Fp12.Storage, rhs: Fp12.Storage) -> Bool {
        rhs.withUnsafeLowLevelAccess { r in
            lhs.withUnsafeLowLevelAccess { l in
                blst_fp12_is_equal(r, l)
            }
        }
    }
}

internal extension Fp12.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}


internal extension Fp12.Storage {
    func isInGroup() -> Bool {
        withUnsafeLowLevelAccess {
            blst_fp12_in_group($0)
        }
    }
}
