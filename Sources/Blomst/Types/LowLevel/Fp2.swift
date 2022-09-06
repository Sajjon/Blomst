//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST

public struct Fp2: Equatable {
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}

public extension Fp2 {
    var real: Fp1 {
        storage.real
    }
    var imaginary: Fp1 {
        storage.imaginary
    }
}

internal extension Fp2 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}


internal extension Fp2 {
    final class Storage: Equatable {
        typealias LowLevel = blst_fp2
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fp2.Storage {
    
    var real: Fp1 {
        .init(storage: .init(lowLevel:  lowLevel.fp.0))
    }
  
    var imaginary: Fp1 {
        .init(storage: .init(lowLevel:  lowLevel.fp.1))
    }
}


internal extension Fp2.Storage {
    static func ==(lhs: Fp2.Storage, rhs: Fp2.Storage) -> Bool {
        var l = lhs.lowLevel
        var r = rhs.lowLevel
        return withUnsafeBytes(of: &l) { lBytes in
            withUnsafeBytes(of: &r) { rBytes in
                safeCompare(lBytes, rBytes)
            }
        }
    }
}


internal extension Fp2.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}
