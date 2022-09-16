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

#if DEBUG
extension Fr: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt64
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(uint64: value)
    }
}
public extension Fr {
    init(uint64: UInt64) {
        self.init(storage: .init(uint64: uint64))
    }
}

#endif // DEBUG

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

#if DEBUG
extension Fr.Storage: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt64
    convenience init(integerLiteral value: IntegerLiteralType) {
        self.init(uint64: value)
    }
}
extension Fr.Storage {
    convenience init(uint64: UInt64) {
        self.init(uint64s: [0, 0, 0, uint64])
    }
    convenience init(uint64s: [UInt64]) {
        precondition(uint64s.count == 4)
        var uint64s = uint64s
        var lowLevel = LowLevel()
        blst_fr_from_uint64(&lowLevel, &uint64s)
        self.init(lowLevel: lowLevel)
    }
}

#endif // DEBUG


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
