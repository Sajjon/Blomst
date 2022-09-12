//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST
import BytePattern

public struct Fp1: Equatable, CustomStringConvertible, DataSerializable {
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
}

public extension Fp1 {
    init(mostSignificantUInt64: UInt64) {
        self.init(storage: .init(mostSignificantUInt64: mostSignificantUInt64))
    }
    
    init(uint64s: [UInt64]) {
        self.init(storage: .init(uint64s: uint64s))
    }
    
    init(mostSignificantUInt32: UInt32) {
        self.init(storage: .init(mostSignificantUInt32: mostSignificantUInt32))
    }
    
    init(uint32s: [UInt32]) {
        self.init(storage: .init(uint32s: uint32s))
    }
}

public extension Fp1 {
    var description: String {
        hex()
    }
}

public extension Fp1 {
    func toData() -> Data {
        storage.toData()
    }
}

internal extension Fp1 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

// MARK: AdditiveArithmetic
extension Fp1: AdditiveArithmetic, ExpressibleByIntegerLiteral {}
public extension Fp1 {
    static let zero = Self(storage: .zero)
    
    static func + (lhs: Self, rhs: Self) -> Self {
        .init(storage: lhs.storage + rhs.storage)
    }
    
    static func - (lhs: Self, rhs: Self) -> Self {
        .init(storage: lhs.storage - rhs.storage)
    }
    
    static func * (lhs: Self, rhs: Self) -> Self {
        .init(storage: lhs.storage * rhs.storage)
    }
}
// MARK: Ex
public extension Fp1 {
    typealias IntegerLiteralType = UInt64
    init(integerLiteral mostSignificantUInt64: IntegerLiteralType) {
        self.init(mostSignificantUInt64: mostSignificantUInt64)
    }
}

internal extension Fp1 {
    final class Storage: Equatable, ExpressibleByIntegerLiteral, AdditiveArithmetic, DataSerializable {
        typealias LowLevel = blst_fp
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fp1.Storage {
    
    convenience init(mostSignificantUInt64: UInt64) {
        self.init(uint64s: [mostSignificantUInt64, 0, 0, 0, 0, 0])
    }
    
    convenience init(uint64s: [UInt64]) {
        precondition(uint64s.count == 6)
//        var uint64s = uint64s
        let lowLevel = uint64s.withUnsafeBufferPointer {
            var lowLevel = LowLevel()
            blst_fp_from_uint64(&lowLevel, $0.baseAddress)
            return lowLevel
        }
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(mostSignificantUInt32: UInt32) {
        self.init(uint32s: [mostSignificantUInt32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    }
    
    convenience init(uint32s: [UInt32]) {
        precondition(uint32s.count == 12)
        var uint32s = uint32s
        var lowLevel = LowLevel()
        blst_fp_from_uint32(&lowLevel, &uint32s)
        self.init(lowLevel: lowLevel)
    }
}

internal extension Fp1.Storage {
    static func ==(lhs: Fp1.Storage, rhs: Fp1.Storage) -> Bool {
     
        var l = lhs.lowLevel
        var r = rhs.lowLevel
        return Swift.withUnsafeBytes(of: &l) { lBytes in
            Swift.withUnsafeBytes(of: &r) { rBytes in
                safeCompare(lBytes, rBytes)
            }
        }
    }
}


internal extension Fp1.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}

internal extension Fp1.Storage {
    
    typealias IntegerLiteralType = UInt64
    convenience init(integerLiteral mostSignificantUInt64: UInt64) {
        self.init(mostSignificantUInt64: mostSignificantUInt64)
    }
    
    static func * (lhs: Fp1.Storage, rhs: Fp1.Storage) -> Fp1.Storage {
        lhs.withUnsafeLowLevelAccess { l in
            rhs.withUnsafeLowLevelAccess { r in
                var ret = LowLevel()
                blst_fp_mul(&ret, l, r)
                return .init(lowLevel: ret)
            }
        }
    }
    
    static let zero = Fp1.Storage(mostSignificantUInt32: 0)
    
    static func + (lhs: Fp1.Storage, rhs: Fp1.Storage) -> Fp1.Storage {
        lhs.withUnsafeLowLevelAccess { l in
            rhs.withUnsafeLowLevelAccess { r in
                var ret = LowLevel()
                blst_fp_add(&ret, l, r)
                return .init(lowLevel: ret)
            }
        }
    }
    
    static func - (lhs: Fp1.Storage, rhs: Fp1.Storage) -> Fp1.Storage {
        lhs.withUnsafeLowLevelAccess { l in
            rhs.withUnsafeLowLevelAccess { r in
                var ret = LowLevel()
                blst_fp_sub(&ret, l, r)
                return .init(lowLevel: ret)
            }
        }
    }
}

internal extension Fp1.Storage {
    func toData() -> Data {
//        var lowLevel = self.lowLevel
        let uint64s = Swift.withUnsafeBytes(of: lowLevel.l) {
//            $0.load(as: [UInt64].self)
            $0.bindMemory(to: UInt64.self)
        }
        return uint64s.map { $0.data }.reduce(Data()) { $0 + $1 }
//        return Data(bytes)
    }
}