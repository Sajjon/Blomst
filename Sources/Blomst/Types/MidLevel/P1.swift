//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` **projective** point, having three coordinates: `x, y, z`.
/// **NOT NECESSARILY IN THE GROUP **`G1`, for that use `G1Projective`
public struct P1:
    Equatable,
    UncompressedDataSerializable,
    ProjectivePoint,
    UncompressedDataRepresentable,
    CompressedDataRepresentable,
    CustomStringConvertible
{
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(storage: lhs.storage + rhs.storage)
    }
    
    internal let storage: Storage
    
    public static var generator: Self {
        .init(storage: .generator)
    }
    
    public static var identity: Self {
        .init(storage: .identity)
    }
    
    public var description: String {
        """
        P1(
            x: 0x\(x)
            y: 0x\(y)
            z: 0x\(z)
        )
        """
    }
    
    internal init(storage: Storage) {
        self.storage = storage
    }
    
    public init(x: Fp1, y: Fp1, z: Fp1) {
        self.init(storage: .init(x: x, y: y, z: z))
    }
}


public extension P1 {
    typealias Component = Fp1
    var x: Component {
        storage.x
    }
    var y: Component {
        storage.y
    }
    var z: Component {
        storage.z
    }
    
    var isInfinity: Bool {
        storage.isInfinity
    }
}


public extension P1 {
    func isElementInGroupG1() -> Bool {
        withUnsafeLowLevelAccess {
            blst_p1_in_g1($0)
        }
    }
}

public extension P1 {
    init(uncompressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(uncompressedData: uncompressedData))
    }
    
    init(compressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(compressedData: compressedData))
    }
}

internal extension P1 {
    init(lowLevel: Storage.LowLevel) {
        self.init(storage: .init(lowLevel: lowLevel))
    }
    
    init(affine: Affine) {
        self.init(storage: .init(affine: affine.storage))
    }
}


internal extension P1 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

// MARK: ProjectivePoint
public extension P1 {
    typealias Affine = P1Affine
    func affine() -> Affine {
        .init(storage: storage.affine())
    }
}

// MARK: UncompressedDataSerializable
public extension P1 {
    func uncompressedData() throws -> Data {
        try storage.uncompressedData()
    }
}

// MARK: Storage
internal extension P1 {
    /// A wrapper of `BLS12-381` point, having three coordinates: `x, y, z`.
    final class Storage:
        Equatable,
        UncompressedDataSerializable,
        UncompressedDataRepresentable,
        ProjectivePoint,
        CompressedDataRepresentable
    {
        internal typealias LowLevel = blst_p1
        private let lowLevel: LowLevel
   
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
            withUnsafeLowLevelAccess {
                precondition(blst_p1_on_curve($0))
            }
        }
        
       
    }
}

internal extension P1.Storage {
    
    convenience init(x: Fp1, y: Fp1, z: Fp1) {
        let lowLevel = x.withUnsafeLowLevelAccess { xp in
            y.withUnsafeLowLevelAccess { yp in
                z.withUnsafeLowLevelAccess { zp in
                    LowLevel(x: xp.pointee, y: yp.pointee, z: zp.pointee)
                }
            }
        }
        self.init(lowLevel: lowLevel)
    }
    
    static func + (lhs: P1.Storage, rhs: P1.Storage) -> P1.Storage {
        lhs.withUnsafeLowLevelAccess { l in
            rhs.withUnsafeLowLevelAccess { r in
                var result = LowLevel()
                blst_p1_add(&result, l, r)
                return P1.Storage(lowLevel: result)
            }
        }
    }
    
    
    static var generator: P1.Storage {
        guard let generator = blst_p1_generator() else {
            fatalError()
        }
        return P1.Storage(lowLevel: generator.pointee)
    }
    
    static var identity: P1.Storage {
        fatalError()
    }
    
    static var byteCount: Int {
        blst_p1_sizeof()
    }
}

internal extension P1.Storage {
    var x: Fp1 {
        .init(storage: .init(lowLevel: lowLevel.x))
    }
    var y: Fp1 {
        .init(storage: .init(lowLevel: lowLevel.y))
    }
    var z: Fp1 {
        .init(storage: .init(lowLevel: lowLevel.z))
    }
    
    var isInfinity: Bool {
        withUnsafeLowLevelAccess {
            blst_p1_is_inf($0)
        }
    }
}



internal extension P1.Storage {
    convenience init(affine: Affine) {
        var lowLevel = LowLevel()
        affine.withUnsafeLowLevelAccess {
            blst_p1_from_affine(&lowLevel, $0)
        }
        self.init(lowLevel: lowLevel)
    }
    
    convenience init(uncompressedData: some ContiguousBytes) throws {
        let affine = try Affine(uncompressedData: uncompressedData)
        self.init(affine: affine)
    }
    
    convenience init(compressedData: some ContiguousBytes) throws {
        let affine = try Affine(compressedData: compressedData)
        self.init(affine: affine)
    }
}


internal extension P1.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}

// MARK: ProjectivePoint
internal extension P1.Storage {
    typealias Affine = P1Affine.Storage
    func affine() -> Affine {
        var affine = blst_p1_affine()
        var p1 = self.lowLevel
        blst_p1_to_affine(&affine, &p1)
        return .init(lowLevel: affine)
    }
}

// MARK: Storage + Equatable
internal extension P1.Storage {
    static func ==(lhs: P1.Storage, rhs: P1.Storage) -> Bool {
        var lhsPoint = lhs.lowLevel
        var rhsPoint = rhs.lowLevel
        return blst_p1_is_equal(&lhsPoint, &rhsPoint)
    }
}

// MARK: Storage + UncompressedDataSerializable
internal extension P1.Storage {
    func uncompressedData() throws -> Data {
        var out = Data(repeating: 0x00, count: blst_p1_sizeof())
        var p1 = self.lowLevel
        out.withUnsafeMutableBytes {
            blst_p1_serialize($0.baseAddress, &p1)
        }
        return out
    }
}

