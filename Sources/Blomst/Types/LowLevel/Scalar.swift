//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

public struct Scalar: Equatable, DataSerializable, DataRepresentable {
    internal let storage: Storage
    internal init(storage: Storage) {
        self.storage = storage
    }
    
    public init<D: ContiguousBytes>(data: D) throws {
        try self.init(storage: .init(data: data))
    }
}

// DataSerializable
public extension Scalar {
    func toData() -> Data {
        storage.toData()
    }
}

internal extension Scalar {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

internal extension Scalar {
    final class Storage: Equatable, DataSerializable, DataRepresentable {
        typealias LowLevel = blst_scalar
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Scalar.Storage {
    
    enum Error: Swift.Error {
        case failedToCreateScalarFromBytes
    }
    
    convenience init<D: ContiguousBytes>(data: D) throws {
        var lowLevel = LowLevel()
        try data.withUnsafeBytes { inBytes in
            guard blst_scalar_from_be_bytes(&lowLevel, inBytes.baseAddress, inBytes.count) else {
                throw Error.failedToCreateScalarFromBytes
            }
        }
        self.init(lowLevel: lowLevel)
    }
}

internal extension Scalar.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}


// MARK: Equatable
internal extension Scalar.Storage {
    static func ==(lhs: Scalar.Storage, rhs: Scalar.Storage) -> Bool {
        var l = lhs.lowLevel
        var r = rhs.lowLevel
        return withUnsafeBytes(of: &l) { lhsBytes in
            withUnsafeBytes(of: &r) { rhsBytes in
                safeCompare(lhsBytes, rhsBytes)
            }
        }
    }
}

internal extension Scalar.Storage {
    func toData() -> Data {
        var lowLevel = self.lowLevel
        return withUnsafeBytes(of: &lowLevel) {
            Data($0)
        }
    }
}
