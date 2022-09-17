//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` **affine** point, having two coordinates: `x, y`
public struct P1Affine:
    Equatable,
    AffinePoint,
    UncompressedDataSerializable,
    CompressedDataSerializable,
    UncompressedDataRepresentable,
    CompressedDataRepresentable,
    CustomStringConvertible
{
    public var description: String {
        """
        P1Affine(
            x: 0x\(x)
            y: 0x\(y)
        )
        """
    }
    internal let storage: Storage
    
    internal init(storage: Storage) {
        self.storage = storage
    }
    
    internal init(lowLevel: Storage.LowLevel) {
        self.init(storage: .init(lowLevel: lowLevel))
    }
    
    public init(x: Fp1, y: Fp1) {
        self.init(storage: .init(x: x, y: y))
    }
}


public extension P1Affine {
    var x: Fp1 {
        storage.x
    }
    var y: Fp1 {
        storage.y
    }
    
    var isInfinity: Bool {
        storage.isInfinity
    }
}

public extension P1Affine {
    init(uncompressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(uncompressedData: uncompressedData))
    }
    init(compressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(compressedData: compressedData))
    }
}

public extension P1Affine {
    func isElementInGroupG1() -> Bool {
        withUnsafeLowLevelAccess {
            blst_p1_affine_in_g1($0)
        }
    }
}

#if DEBUG
internal extension P1Affine {
    init() {
        self.init(storage: .init())
    }
}
#endif // DEBUG

internal extension P1Affine {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

// MARK: UncompressedDataSerializable
public extension P1Affine {
    func uncompressedData() throws -> Data {
        try storage.uncompressedData()
    }
}

// MARK: CompressedDataSerializable
public extension P1Affine {
    func compressedData() throws -> Data {
        try storage.compressedData()
    }
}

// MARK: Storage
internal extension P1Affine {
    /// A wrapper of `BLS12-381` **affine** point, having two coordinates: `x, y`.
    final class Storage:
        Equatable,
        UncompressedDataSerializable,
        UncompressedDataRepresentable,
        CompressedDataSerializable,
        CompressedDataRepresentable,
        AffinePoint
    {
        
        internal typealias LowLevel = blst_p1_affine
        
        private let lowLevel: LowLevel
        
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
        
        public convenience init(x: Fp1, y: Fp1) {
            let lowLevel = x.withUnsafeLowLevelAccess { xp in
                y.withUnsafeLowLevelAccess { yp in
                    LowLevel(x: xp.pointee, y: yp.pointee)
                }
            }
            self.init(lowLevel: lowLevel)
         }
    }
}

internal extension P1Affine.Storage {
    var x: Fp1 {
        .init(lowLevel: lowLevel.x)
    }
    var y: Fp1 {
        .init(lowLevel: lowLevel.y)
    }
    
    var isInfinity: Bool {
        P1.Storage.init(affine: self).isInfinity
    }
}

internal extension P1Affine.Storage {
    enum Error: Swift.Error, Equatable {
        case failedToDeserializeFromBytes
    }
    convenience init(uncompressedData: some ContiguousBytes) throws {
        var lowLevel = LowLevel()
        try uncompressedData.withUnsafeBytes { inBytes in
            guard blst_p1_deserialize(&lowLevel, inBytes.baseAddress) == BLST_SUCCESS else {
                throw Error.failedToDeserializeFromBytes
            }
        }
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(compressedData: some ContiguousBytes) throws {
        var lowLevel = LowLevel()
        try compressedData.withUnsafeBytes { inBytes in
            guard blst_p1_uncompress(&lowLevel, inBytes.baseAddress) == BLST_SUCCESS else {
                throw Error.failedToDeserializeFromBytes
            }
        }
        self.init(lowLevel: lowLevel)
    }
}

internal extension P1Affine.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}

// MARK: Storage + Equatable
import BytePattern
internal extension P1Affine.Storage {
    static func ==(lhs: P1Affine.Storage, rhs: P1Affine.Storage) -> Bool {
        var lhsPoint = lhs.lowLevel
        var rhsPoint = rhs.lowLevel
        return blst_p1_affine_is_equal(&lhsPoint, &rhsPoint)
    }
}

// MARK: Storage + UnompressedDataSerializable
internal extension P1Affine.Storage {
    func uncompressedData() throws -> Data {
        var out = Data(repeating: 0x00, count: blst_p1_affine_sizeof())
        var p1 = self.lowLevel
        out.withUnsafeMutableBytes {
            blst_p1_affine_serialize($0.baseAddress, &p1)
        }
        return out
    }
}
// MARK: Storage + CompressedDataSerializable
internal extension P1Affine.Storage {
    func compressedData() throws -> Data {
        var copy = self.lowLevel
        var compressed = Data(repeating: 0x00, count: 48)
        compressed.withUnsafeMutableBytes { outPtr in
            blst_p1_affine_compress(outPtr.baseAddress, &copy)
            
        }
        return compressed
    }
}

#if DEBUG
internal extension P1Affine.Storage {
    convenience init() {
        guard let p1AffinePointer = blst_p1_affine_generator() else {
            fatalError()
        }
        self.init(lowLevel:  p1AffinePointer.pointee)
    }
}
#endif // DEBUG
