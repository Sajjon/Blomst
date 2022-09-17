//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST
import BytePattern

public protocol FromBigEndianBytes {
    init<D>(bigEndian: D) throws where D: ContiguousBytes
}
public protocol FromLittleEndianBytes {
    init<D>(bigEndian: D) throws where D: ContiguousBytes
}

public struct Fp1:
    Equatable,
    PointComponentProtocol,
    CustomStringConvertible,
    UncompressedDataSerializable,
    UncompressedDataRepresentable,
    FromBigEndianBytes,
    FromLittleEndianBytes
{
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }

    public init(bigEndian: some ContiguousBytes) throws {
        try self.init(storage: .init(bigEndian: bigEndian))
    }
    public init(littleEndian: some ContiguousBytes) throws {
        try self.init(storage: .init(littleEndian: littleEndian))
    }
    
    public init(uncompressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(uncompressedData: uncompressedData))
    }
}

internal extension Fp1 {
    init(lowLevel: Storage.LowLevel) {
        self.init(storage: .init(lowLevel: lowLevel))
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
        try! uncompressedData().hex()
    }
}

public extension Fp1 {
    func uncompressedData() throws -> Data {
        try storage.uncompressedData()
    }
}

internal extension Fp1 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

// MARK: AdditiveArithmetic
extension Fp1: ExpressibleByIntegerLiteral {}
public extension Fp1 {
    static let zero = Self(storage: .zero)
    static let one = Self(storage: .one)
    
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
    final class Storage:
        Equatable,
        ExpressibleByIntegerLiteral,
        PointComponentProtocol,
        UncompressedDataSerializable,
        UncompressedDataRepresentable,
        FromBigEndianBytes
    {
        typealias LowLevel = blst_fp
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fp1.Storage {
    
    static func from_bytes(_ bytes: some ContiguousBytes) throws -> Self {
        /*
         let mut tmp = Fp([0, 0, 0, 0, 0, 0]);

               tmp.0[5] = u64::from_be_bytes(<[u8; 8]>::try_from(&bytes[0..8]).unwrap());
               tmp.0[4] = u64::from_be_bytes(<[u8; 8]>::try_from(&bytes[8..16]).unwrap());
               tmp.0[3] = u64::from_be_bytes(<[u8; 8]>::try_from(&bytes[16..24]).unwrap());
               tmp.0[2] = u64::from_be_bytes(<[u8; 8]>::try_from(&bytes[24..32]).unwrap());
               tmp.0[1] = u64::from_be_bytes(<[u8; 8]>::try_from(&bytes[32..40]).unwrap());
               tmp.0[0] = u64::from_be_bytes(<[u8; 8]>::try_from(&bytes[40..48]).unwrap());

               // Try to subtract the modulus
               let (_, borrow) = sbb(tmp.0[0], MODULUS[0], 0);
               let (_, borrow) = sbb(tmp.0[1], MODULUS[1], borrow);
               let (_, borrow) = sbb(tmp.0[2], MODULUS[2], borrow);
               let (_, borrow) = sbb(tmp.0[3], MODULUS[3], borrow);
               let (_, borrow) = sbb(tmp.0[4], MODULUS[4], borrow);
               let (_, borrow) = sbb(tmp.0[5], MODULUS[5], borrow);

               // If the element is smaller than MODULUS then the
               // subtraction will underflow, producing a borrow value
               // of 0xffff...ffff. Otherwise, it'll be zero.
               let is_some = (borrow as u8) & 1;

               // Convert to Montgomery form by computing
               // (a.R^0 * R^2) / R = a.R
               tmp *= &R2;

               CtOption::new(tmp, Choice::from(is_some))
         */
        var lowLevel = LowLevel()
        
        lowLevel.l.0 = 0
        return Self.init(lowLevel: lowLevel)
    }
    
    convenience init(bigEndian: some ContiguousBytes) throws {
        var lowLevel = LowLevel()
        bigEndian.withUnsafeBytes { be in
            blst_fp_from_bendian(&lowLevel, be.baseAddress)
        }
        self.init(lowLevel: lowLevel)
    }

    convenience init(littleEndian: some ContiguousBytes) throws {
        var lowLevel = LowLevel()
        littleEndian.withUnsafeBytes { le in
            blst_fp_from_lendian(&lowLevel, le.baseAddress)
        }
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(uncompressedData: some ContiguousBytes) throws {
        var lowLevel = LowLevel()
        Swift.withUnsafePointer(to: &lowLevel) { llc in
            uncompressedData.withUnsafeBytes { source in
                let targetStart = UnsafeMutablePointer(mutating: llc)
                let target = UnsafeMutableBufferPointer(start: targetStart, count: 48)
                source.copyBytes(to: target)
            }
        }
        self.init(lowLevel: lowLevel)
    }
}
internal extension Fp1.Storage {
    
    convenience init(mostSignificantUInt64: UInt64) {
        self.init(uint64s: [mostSignificantUInt64, 0, 0, 0, 0, 0])
    }
    
    convenience init(uint64s: [UInt64]) {
        precondition(uint64s.count == 6)
        var uint64s = uint64s
//        var uint64s =  [UInt64](uint64s.map { $0.littleEndian }.reversed())
        var lowLevel = LowLevel()
        blst_fp_from_uint64(&lowLevel, &uint64s)
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(mostSignificantUInt32: UInt32) {
        self.init(uint32s: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, mostSignificantUInt32])
    }
    
    convenience init(uint32s: [UInt32]) {
        precondition(uint32s.count == 12)
        var uint64s =  [UInt32](uint32s.map { $0.littleEndian }.reversed())
        var lowLevel = LowLevel()
        blst_fp_from_uint32(&lowLevel, &uint64s)
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
    
    static let zero = try! Fp1.Storage(uncompressedData: try! Data(hex: "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"))
    static let one = try! Fp1.Storage(uncompressedData: try! Data(hex: "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"))
    
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
   
    /// This function yield identical result as
    ///
    /// func uncompressedData() throws -> Data {
    ///     var lowLevelCopy = self.lowLevel
    ///     var data = Data.init(repeating: 0xff, count: 48)
    ///
    ///     Swift.withUnsafePointer(to: &lowLevelCopy) { llc in
    ///         data.withUnsafeMutableBytes { target in
    ///             let source = UnsafeRawBufferPointer.init(start: llc, count: 48)
    ///             target.copyBytes(from: source)
    ///         }
    ///     }
    ///
    ///     return data
    /// }
    func uncompressedData() throws -> Data {
        let uint64s = Swift.withUnsafeBytes(of: lowLevel.l) {
            $0.bindMemory(to: UInt64.self)
        }
        return uint64s.map { $0.bigEndian.data }.reduce(Data()) { $0 + $1 }
    }
        
}
