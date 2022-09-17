//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` **projective** point, having three coordinates: `x, y, z`.
/// /// **NOT NECESSARILY IN THE GROUP **`G2`, for that use `G2Projective`
public struct P2:
    Equatable,
    UncompressedDataRepresentable,
    UncompressedDataSerializable,
    ProjectivePoint
{
    public init(x: Fp2, y: Fp2, z: Fp2) throws {
        try self.init(storage: .init(x: x, y: y, z: z))
    }
    
    public typealias Component = Fp2
    
    public var x: Component {
        storage.x
    }
    public var y: Component {
        storage.y
    }
    public var z: Component {
        storage.z
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(storage: lhs.storage + rhs.storage)
    }
    
    public static var generator: Self {
        .init(storage: .generator)
    }
    
    public static var identity: Self {
        .init(storage: .identity)
    }
    
    internal let storage: Storage
    
    internal init(storage: Storage) {
        self.storage = storage
    }
    
    internal init(lowLevel: Storage.LowLevel) {
        self.init(storage: .init(lowLevel: lowLevel))
    }
    
    internal init(affine: Affine) {
        self.init(storage: .init(affine: affine.storage))
    }
}

public extension P2 {
    init(uncompressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(uncompressedData: uncompressedData))
    }
    
    init(compressedData: some ContiguousBytes) throws {
        try self.init(storage: .init(compressedData: compressedData))
    }
}

public extension P2 {
    func isElementInGroupG2() -> Bool {
        withUnsafeLowLevelAccess {
            blst_p2_in_g2($0)
        }
    }
}


#if DEBUG
internal extension P2 {
    init() {
        self.init(storage: .init())
    }
}
#endif // DEBUG

internal extension P2 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

// MARK: ProjectivePoint
public extension P2 {
    typealias Affine = P2Affine
    func affine() -> Affine {
        .init(storage: storage.affine())
    }
}


// MARK: UncompressedDataSerializable
public extension P2 {
    func uncompressedData() throws -> Data {
        try storage.uncompressedData()
    }
}

// MARK: Storage
internal extension P2 {
    /// A wrapper of `BLS12-381` point, having three coordinates: `x, y, z`.
    final class Storage: Equatable, UncompressedDataRepresentable, UncompressedDataSerializable, ProjectivePoint {
        convenience init(x: Fp2, y: Fp2, z: Fp2) throws {
            let lowLevel: LowLevel = x.withUnsafeLowLevelAccess { xL in
                y.withUnsafeLowLevelAccess { yL in
                    z.withUnsafeLowLevelAccess { zL in
                        return blst_p2(x: xL.pointee, y: yL.pointee, z: zL.pointee)
                    }
                }
            }
            self.init(lowLevel: lowLevel)
        }
        
        typealias Component = Fp2
        
        static var generator: P2.Storage {
            fatalError()
        }
        
        static var identity: P2.Storage {
            try! .init(x: .zero, y: .one, z: .zero)
        }
        
        var x: Component {
            .init(lowLevel: lowLevel.x)
        }
        var y: Component {
            .init(lowLevel: lowLevel.y)
        }
        var z: Component {
            .init(lowLevel: lowLevel.z)
        }
        
        static func + (lhs: P2.Storage, rhs: P2.Storage) -> P2.Storage {
            let sum = lhs.withUnsafeLowLevelAccess { l in
                rhs.withUnsafeLowLevelAccess { r in
                    var result = LowLevel()
                    blst_p2_add(&result, l, r)
                    return result
                }
            }
            return P2.Storage(lowLevel: sum)
        }
        
        internal typealias LowLevel = blst_p2
        private let lowLevel: LowLevel
        
    
        
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
            withUnsafeLowLevelAccess {
                precondition(blst_p2_on_curve($0))
            }
        }
    }
}

internal extension P2.Storage {
    convenience init(affine: Affine) {
        var lowLevel = LowLevel()
        affine.withUnsafeLowLevelAccess {
            blst_p2_from_affine(&lowLevel, $0)
        }
        self.init(lowLevel: lowLevel)
    }
}

internal extension P2.Storage {
    convenience init(uncompressedData: some ContiguousBytes) throws {
        let affine = try Affine(uncompressedData: uncompressedData)
        self.init(affine: affine)
    }
    
    convenience init(compressedData: some ContiguousBytes) throws {
        let affine = try Affine(compressedData: compressedData)
        self.init(affine: affine)
    }
}

internal extension P2.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}

// MARK: ProjectivePoint
internal extension P2.Storage {
    typealias Affine = P2Affine.Storage
    func affine() -> Affine {
        var affine = blst_p2_affine()
        var p2 = self.lowLevel
        blst_p2_to_affine(&affine, &p2)
        return .init(lowLevel: affine)
    }
}

// MARK: Storage + Equatable
internal extension P2.Storage {
    static func ==(lhs: P2.Storage, rhs: P2.Storage) -> Bool {
        var lhsPoint = lhs.lowLevel
        var rhsPoint = rhs.lowLevel
        return blst_p2_is_equal(&lhsPoint, &rhsPoint)
    }
}

// MARK: Storage + UncompressedDataSerializable
internal extension P2.Storage {
    func uncompressedData() throws -> Data {
        var out = Data(repeating: 0x00, count: blst_p2_sizeof())
        var p2 = self.lowLevel
        out.withUnsafeMutableBytes {
            blst_p2_serialize($0.baseAddress, &p2)
        }
        return out
    }
}


#if DEBUG
internal extension P2.Storage {
    convenience init() {
        guard let p2Pointer = blst_p2_generator() else {
            fatalError()
        }
        self.init(lowLevel:  p2Pointer.pointee)
    }
}
#endif // DEBUG
