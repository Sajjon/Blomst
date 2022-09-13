//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST
import BytePattern

public struct Scalar: Equatable, UncompressedDataSerializable, UncompressedDataRepresentable {
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
    
    init<D: ContiguousBytes>(uncompressedData: D) throws {
        try self.init(storage: .init(uncompressedData: uncompressedData))
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

// MARK: UncompressedDataSerializable
public extension Scalar {
    func uncompressedData() throws -> Data {
        try storage.uncompressedData()
    }
}

internal extension Scalar {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

internal extension Scalar {
    final class Storage: Equatable, UncompressedDataSerializable, UncompressedDataRepresentable {
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
        self.init(uint32s: [0, 0, 0, 0, 0, 0, 0, mostSignificantUInt32])
    }
    
    convenience init(uint32s: [UInt32]) {

        precondition(uint32s.count == 8)
        var uint64s =  [UInt32](uint32s.map { $0.littleEndian }.reversed())
        var lowLevel = LowLevel()
        blst_scalar_from_uint32(&lowLevel, &uint64s)
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(mostSignificantUInt64: UInt64) {
        self.init(uint64s: [0, 0, 0, mostSignificantUInt64])
    }
    
    convenience init(uint64s: [UInt64]) {
        precondition(uint64s.count == 4)
        var uint64s =  [UInt64](uint64s.map { $0.littleEndian }.reversed())
        var lowLevel = LowLevel()
        blst_scalar_from_uint64(&lowLevel, &uint64s)
        self.init(lowLevel: lowLevel)
    }
    
    enum Error: Swift.Error {
        case failedToCreateScalarFromBytes
    }
    
    convenience init<D: ContiguousBytes>(uncompressedData: D) throws {
        var lowLevel = LowLevel()
        try uncompressedData.withUnsafeBytes { inBytes in
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
    func uncompressedData() throws -> Data {
        var lowLevel = self.lowLevel
        return Swift.withUnsafeBytes(of: &lowLevel) {
            Data($0)
        }
    }
}
