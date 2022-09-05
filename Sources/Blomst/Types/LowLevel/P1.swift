//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` point, having three coordinates: `x, y, z`.
/// **NOT NECESSARILY IN THE GROUP **`G1`, for that use `G1Element`
public struct P1: Equatable, DataSerializable, AffineSerializable, DataRepresentable {
    internal let storage: Storage
    
    internal init(storage: Storage) {
        self.storage = storage
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
    init<D>(data: D) throws where D : ContiguousBytes {
        try self.init(storage: .init(data: data))
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

#if DEBUG
internal extension P1 {
    init() {
        self.init(storage: .init())
    }
}
#endif // DEBUG

internal extension P1 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}

// MARK: AffineSerializable
public extension P1 {
    typealias Affine = P1Affine
    func affine() -> Affine {
        .init(storage: storage.affine())
    }
}

// MARK: DataSerializable
public extension P1 {
    func toData() -> Data {
        storage.toData()
    }
}

// MARK: Storage
internal extension P1 {
    /// A wrapper of `BLS12-381` point, having three coordinates: `x, y, z`.
    final class Storage: Equatable, DataSerializable, DataRepresentable {
        internal typealias LowLevel = blst_p1
        private let lowLevel: LowLevel
        
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
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
    
    convenience init<D>(data: D) throws where D : ContiguousBytes {
        let affine = try Affine(data: data)
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

// MARK: AffineSerializable
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

// MARK: Storage + DataSerializable
internal extension P1.Storage {
    func toData() -> Data {
        var out = Data(repeating: 0x00, count: blst_p1_sizeof())
        var p1 = self.lowLevel
        out.withUnsafeMutableBytes {
            blst_p1_serialize($0.baseAddress, &p1)
        }
        return out
    }
}

#if DEBUG
internal extension P1.Storage {
    convenience init() {
        guard let p1Pointer = blst_p1_generator() else {
            fatalError()
        }
        self.init(lowLevel:  p1Pointer.pointee)
    }
}
#endif // DEBUG
