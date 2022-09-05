//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` point, having three coordinates: `x, y, z`.
/// /// **NOT NECESSARILY IN THE GROUP **`G2`, for that use `G2Element`
public struct P2: Equatable, DataSerializable, AffineSerializable {
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
    init<D>(data: D) throws where D : ContiguousBytes {
        try self.init(storage: .init(data: data))
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

// MARK: AffineSerializable
public extension P2 {
    typealias Affine = P2Affine
    func affine() -> Affine {
        .init(storage: storage.affine())
    }
}


// MARK: DataSerializable
public extension P2 {
    func toData() -> Data {
        storage.toData()
    }
}

// MARK: Storage
internal extension P2 {
    /// A wrapper of `BLS12-381` point, having three coordinates: `x, y, z`.
    final class Storage: Equatable, DataSerializable, AffineSerializable {
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
    convenience init<D>(data: D) throws where D : ContiguousBytes {
        let affine = try Affine(data: data)
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

// MARK: AffineSerializable
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

// MARK: Storage + DataSerializable
internal extension P2.Storage {
    func toData() -> Data {
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
