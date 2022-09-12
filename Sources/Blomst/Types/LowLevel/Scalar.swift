//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST
import BytePattern

public struct Scalar: Equatable, DataSerializable, DataRepresentable {
    internal let storage: Storage
    internal init(storage: Storage) {
        self.storage = storage
    }
}

public extension Scalar {
    
    init(fr: Fr) {
        self.init(storage: .init(fr: fr))
    }
    
    init(uint32s: [UInt32]) {
        self.init(storage: .init(uint32s: uint32s))
    }
    
    init(uint64s: [UInt64]) {
        self.init(storage: .init(uint64s: uint64s))
    }
    
    init<D: ContiguousBytes>(data: D) throws {
        try self.init(storage: .init(data: data))
    }
}

#if DEBUG
public extension Scalar {
    
    init(mostSignigicantInt: Int) {
        self.init(mostSignificantUInt64: .init(mostSignigicantInt))
    }
    
    init(mostSignificantUInt32: UInt32) {
        self.init(storage: .init(mostSignificantUInt32: mostSignificantUInt32))
    }
    
    init(mostSignificantUInt64: UInt64) {
        self.init(storage: .init(mostSignificantUInt64: mostSignificantUInt64))
    }
    
}
#endif // DEBUG

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
    
    convenience init(fr: Fr) {
        self.init(frStorage: fr.storage)
    }
    
    convenience init(frStorage: Fr.Storage) {
        var lowLevel = LowLevel()
        frStorage.withUnsafeLowLevelAccess {
            blst_scalar_from_fr(&lowLevel, $0)
        }
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(mostSignificantUInt32: UInt32) {
        self.init(uint32s: [mostSignificantUInt32, 0, 0, 0, 0, 0, 0, 0])
    }
    
    convenience init(uint32s: [UInt32]) {
        precondition(uint32s.count == 8)
        var lowLevel = LowLevel()
        var uint32s = uint32s
        blst_scalar_from_uint32(&lowLevel, &uint32s)
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(mostSignificantUInt64: UInt64) {
        self.init(uint64s: [mostSignificantUInt64, 0, 0, 0])
    }
    
    convenience init(uint64s: [UInt64]) {
        precondition(uint64s.count == 4)
        var lowLevel = LowLevel()
        var uint64s = uint64s
        blst_scalar_from_uint64(&lowLevel, &uint64s)
        self.init(lowLevel: lowLevel)
    }
    
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
        return Swift.withUnsafeBytes(of: &l) { lhsBytes in
            Swift.withUnsafeBytes(of: &r) { rhsBytes in
                safeCompare(lhsBytes, rhsBytes)
            }
        }
    }
}

internal extension Scalar.Storage {
    func toData() -> Data {
        var lowLevel = self.lowLevel
        return Swift.withUnsafeBytes(of: &lowLevel) {
            Data($0)
        }
    }
}
