//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST

public struct Fp6: Equatable {
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}

public extension Fp6 {
    init(fp2 first: Fp2, second: Fp2, third: Fp2) {
        self.init(storage: .init(fp2: first.storage, second: second.storage, third: third.storage))
    }
}

internal extension Fp6 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}


internal extension Fp6 {
    final class Storage: Equatable {
        typealias LowLevel = blst_fp6
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fp6.Storage {
    convenience init(fp2 first: Fp2.Storage, second: Fp2.Storage, third: Fp2.Storage) {
        let lowLevel = first.withUnsafeLowLevelAccess { f in
            second.withUnsafeLowLevelAccess { s in
                third.withUnsafeLowLevelAccess { t in
                    LowLevel(fp2: (f.pointee, s.pointee, t.pointee))
                }
            }
        }
        self.init(lowLevel: lowLevel)
    }
}


internal extension Fp6.Storage {
    static func ==(lhs: Fp6.Storage, rhs: Fp6.Storage) -> Bool {
        var l = lhs.lowLevel
        var r = rhs.lowLevel
        return withUnsafeBytes(of: &l) { lBytes in
            withUnsafeBytes(of: &r) { rBytes in
                safeCompare(lBytes, rBytes)
            }
        }
    }
}

internal extension Fp6.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}
