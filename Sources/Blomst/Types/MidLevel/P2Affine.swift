//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` **affine** point, having two coordinates: `x, y`
public struct P2Affine: Equatable, AffinePoint, UncompressedDataSerializable, UncompressedDataRepresentable, CompressedDataSerializable, CompressedDataRepresentable {
    internal let storage: Storage
    
    internal init(storage: Storage) {
        self.storage = storage
    }
    
    internal init(lowLevel: Storage.LowLevel) {
        self.init(storage: .init(lowLevel: lowLevel))
    }
}

public extension P2Affine {
    init(x: Fp2, y: Fp2) {
        self.init(storage: .init(x: x.storage, y: y.storage))
    }
}

public extension P2Affine {
    init(uncompressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(uncompressedData: uncompressedData))
    }
    init(compressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(compressedData: compressedData))
    }
}

public extension P2Affine {

    var p2: P2 {
        withUnsafeLowLevelAccess { aff in
            var lowLevelOut = blst_p2()
            blst_p2_from_affine(&lowLevelOut, aff)
            return P2(lowLevel: lowLevelOut)
        }
    }
    
    func isElementInGroupG2() -> Bool {
        withUnsafeLowLevelAccess {
            blst_p2_affine_in_g2($0)
        }
    }
    
    var x: Fp2 {
        .init(storage: storage.x)
    }
    
    var y: Fp2 {
        .init(storage: storage.y)
    }
}

#if DEBUG
internal extension P2Affine {
    init() {
        self.init(storage: .init())
    }
}
#endif // DEBUG

internal extension P2Affine {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

// MARK: UncompressedDataSerializable
public extension P2Affine {
    func uncompressedData() throws -> Data {
        try storage.uncompressedData()
    }
}
// MARK: CompressedDataSerializable
public extension P2Affine {
    func compressedData() throws -> Data {
        try storage.compressedData()
    }
}

// MARK: Storage
internal extension P2Affine {
    /// A wrapper of `BLS12-381` **affine** point, having two coordinates: `x, y`.
    final class Storage: Equatable, AffinePoint, UncompressedDataSerializable, UncompressedDataRepresentable, CompressedDataSerializable, CompressedDataRepresentable {
        internal typealias LowLevel = blst_p2_affine
        private let lowLevel: LowLevel
        
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension P2Affine.Storage {
    enum Error: Swift.Error, Equatable {
        case failedToDeserializeFromBytes
    }
    convenience init(uncompressedData: some ContiguousBytes) throws {
        var lowLevel = LowLevel()
        try uncompressedData.withUnsafeBytes { inBytes in
            guard blst_p2_deserialize(&lowLevel, inBytes.baseAddress) == BLST_SUCCESS else {
                throw Error.failedToDeserializeFromBytes
            }
        }
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(compressedData: some ContiguousBytes) throws {
        var lowLevel = LowLevel()
        try compressedData.withUnsafeBytes { inBytes in
            guard blst_p2_uncompress(&lowLevel, inBytes.baseAddress) == BLST_SUCCESS else {
                throw Error.failedToDeserializeFromBytes
            }
        }
        self.init(lowLevel: lowLevel)
    }
    
    var x: Fp2.Storage {
        .init(lowLevel: lowLevel.x)
    }
    var y: Fp2.Storage {
        .init(lowLevel: lowLevel.y)
    }
    
    convenience init(x: Fp2.Storage, y: Fp2.Storage) {
        let lowLevel = x.withUnsafeLowLevelAccess { x_ in
            y.withUnsafeLowLevelAccess { y_ in
                LowLevel(x: x_.pointee, y: y_.pointee)
            }
        }
        self.init(lowLevel: lowLevel)
    }
}

internal extension P2Affine.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
    
    var lowLevelPointer: UnsafePointer<LowLevel> {
        withUnsafeLowLevelAccess { UnsafePointer($0) }
    }
}

// MARK: Storage + Equatable
internal extension P2Affine.Storage {
    static func ==(lhs: P2Affine.Storage, rhs: P2Affine.Storage) -> Bool {
        var lhsPoint = lhs.lowLevel
        var rhsPoint = rhs.lowLevel
        return blst_p2_affine_is_equal(&lhsPoint, &rhsPoint)
    }
}

// MARK: Storage + UncompressedDataSerializable
internal extension P2Affine.Storage {
    func uncompressedData() throws -> Data {
        var out = Data(repeating: 0x00, count: 192)
        var lowLevel = self.lowLevel
        out.withUnsafeMutableBytes {
            blst_p2_affine_serialize($0.baseAddress, &lowLevel)
        }
        return out
    }
}
// MARK: Storage + CompressedDataSerializable
internal extension P2Affine.Storage {
    func compressedData() throws -> Data {
        var out = Data(repeating: 0x00, count: 96)
        var lowLevel = self.lowLevel
        out.withUnsafeMutableBytes { outPtr in
            blst_p2_affine_compress(outPtr.baseAddress, &lowLevel)
        }
        return out
    }
}


#if DEBUG
internal extension P2Affine.Storage {
    convenience init() {
        guard let p2AffinePointer = blst_p2_affine_generator() else {
            fatalError()
        }
        self.init(lowLevel:  p2AffinePointer.pointee)
    }
}
#endif // DEBUG
