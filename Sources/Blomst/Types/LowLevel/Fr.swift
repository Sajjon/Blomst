//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST
import BytePattern

public struct Fr: Equatable {
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}

internal extension Fr {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

internal extension Fr {
    final class Storage: Equatable {
        typealias LowLevel = blst_fr
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fr.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}

internal extension Fr.Storage {
    static func ==(lhs: Fr.Storage, rhs: Fr.Storage) -> Bool {
        var l = lhs.lowLevel
        var r = rhs.lowLevel
        return Swift.withUnsafeBytes(of: &l) { lBytes in
            Swift.withUnsafeBytes(of: &r) { rBytes in
                safeCompare(lBytes, rBytes)
            }
        }
    }
}
