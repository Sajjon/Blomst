//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST
import BytePattern

public struct Fp2:
    Equatable,
    CustomStringConvertible,
    UncompressedDataSerializable,
    PointComponentProtocol
{
    public static func - (lhs: Fp2, rhs: Fp2) -> Fp2 {
        .init(storage: lhs.storage - rhs.storage)
    }
    
    public static func + (lhs: Fp2, rhs: Fp2) -> Fp2 {
        .init(storage: lhs.storage + rhs.storage)
    }
    
    public static var one: Fp2 {
        .init(storage: .one)
    }
    
    public static func * (lhs: Fp2, rhs: Fp2) -> Fp2 {
        .init(storage: lhs.storage + rhs.storage)
    }
    
    public static var zero: Fp2 {
        .init(storage: .zero)
        
    }
    
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
    init(lowLevel: Storage.LowLevel) {
        self.init(storage: .init(lowLevel: lowLevel))
    }
}

public extension Fp2 {
    
    func uncompressedData() throws -> Data {
        try storage.uncompressedData()
    }
    var description: String {
        try! uncompressedData().hex()
    }
}

public extension Fp2 {
    init(real: Fp1, imaginary: Fp1) {
        self.init(storage: .init(real: real.storage, imaginary: imaginary.storage))
    }
}
public extension Fp2 {
    var real: Fp1 {
        storage.real
    }
    var imaginary: Fp1 {
        storage.imaginary
    }
}

internal extension Fp2 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}


internal extension Fp2 {
    final class Storage: Equatable, UncompressedDataSerializable, PointComponentProtocol {
        static func - (lhs: Fp2.Storage, rhs: Fp2.Storage) -> Self {
            fatalError()
        }
        
        static func + (lhs: Fp2.Storage, rhs: Fp2.Storage) -> Fp2.Storage {
            fatalError()
        }
        
        // GUESSING HERE
        static var zero: Fp2.Storage {
            Fp2.Storage(real: .zero, imaginary: .zero)
        }
        
        // GUESSING HERE
        static var one: Fp2.Storage {
            Fp2.Storage(real: .one, imaginary: .one)
        }
        
        // GUESSING HERE
        static func * (lhs: Fp2.Storage, rhs: Fp2.Storage) -> Fp2.Storage {
            let real: Fp1 = lhs.real * rhs.real
            let imaginary: Fp1 = lhs.imaginary * rhs.imaginary
            return Fp2.Storage(
                real: real.storage,
                imaginary: imaginary.storage
            )
        }
        
        typealias LowLevel = blst_fp2
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fp2.Storage {
    convenience init(
        real: Fp1.Storage,
        imaginary: Fp1.Storage
    ) {
        let lowLevel = real.withUnsafeLowLevelAccess { r in
            imaginary.withUnsafeLowLevelAccess { i in
                LowLevel(fp: (r.pointee, i.pointee))
            }
        }
        self.init(lowLevel: lowLevel)
    }
}

internal extension Fp2.Storage {
    
    var real: Fp1 {
        .init(storage: .init(lowLevel:  lowLevel.fp.0))
    }
  
    var imaginary: Fp1 {
        .init(storage: .init(lowLevel:  lowLevel.fp.1))
    }
}


internal extension Fp2.Storage {
    static func ==(lhs: Fp2.Storage, rhs: Fp2.Storage) -> Bool {
        var l = lhs.lowLevel
        var r = rhs.lowLevel
        return Swift.withUnsafeBytes(of: &l) { lBytes in
            Swift.withUnsafeBytes(of: &r) { rBytes in
                safeCompare(lBytes, rBytes)
            }
        }
    }
}


internal extension Fp2.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}

internal extension Fp2.Storage {
    func uncompressedData() throws -> Data {
        var lowLevel = self.lowLevel
        return Swift.withUnsafeBytes(of: &lowLevel) {
            Data($0)
        }
    }
}
