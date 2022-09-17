//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST

public struct Fp12:
    Equatable,
    MultiplicativeArithmetic,
    CustomDebugStringConvertible
{
    internal let storage: Storage
    init(storage: Storage) {
        self.storage = storage
    }
    init(lowLevel: Storage.LowLevel) {
        self.init(storage: .init(lowLevel: lowLevel))
    }
    
    public var debugDescription: String {
        storage.debugDescription
    }
}

public extension Fp12 {
    static let one = Self.init(storage: .one)
    
    
    var first: Fp6 {
        storage.first
    }
    var second: Fp6 {
        storage.second
    }
    
    static func * (lhs: Self, rhs: Self) -> Self {
        Self(storage: lhs.storage * rhs.storage)
    }
    
}

public extension Fp12 {
    init(fp6 first: Fp6, second: Fp6) {
        self.init(storage: .init(fp6: first.storage, second: second.storage))
    }
}
public extension Fp12 {
    func isInGroup() -> Bool {
        storage.isInGroup()
    }
}

internal extension Fp12 {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: @escaping (UnsafeMutablePointer<Storage.LowLevel>) throws -> R) rethrows -> R {
        try storage.withUnsafeLowLevelAccess(access)
    }
}


internal extension Fp12 {
    final class Storage:
        Equatable,
        MultiplicativeArithmetic,
        CustomDebugStringConvertible,
        UncompressedDataSerializable
    {
        static func * (lhs: Fp12.Storage, rhs: Fp12.Storage) -> Fp12.Storage {
            lhs.withUnsafeLowLevelAccess { l in
                rhs.withUnsafeLowLevelAccess { r in
                    var product = LowLevel()
                    blst_fp12_mul(&product, l, r)
                    return Fp12.Storage(lowLevel: product)
                }
            }
        }
        
        var debugDescription: String {
            try! uncompressedData().hex
        }
        
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
            let uint64s = Swift.withUnsafeBytes(of: lowLevel.fp6) {
                $0.bindMemory(to: UInt64.self)
            }
            return uint64s.map { $0.bigEndian.data }.reduce(Data()) { $0 + $1 }
        }
        
        var first: Fp6 {
            .init(storage: .init(lowLevel: lowLevel.fp6.0))
        }
        var second: Fp6 {
            .init(storage: .init(lowLevel: lowLevel.fp6.1))
        }
        
        typealias LowLevel = blst_fp12
        private let lowLevel: LowLevel
        internal init(lowLevel: LowLevel) {
            self.lowLevel = lowLevel
        }
    }
}

internal extension Fp12.Storage {
    
    static let one = Fp12.Storage(fp6: .zero, second: .init(fp2: .zero, second: .zero, third: .one))
    static let zero = Fp12.Storage(fp6: .zero, second: .zero)
    
    convenience init(fp6 first: Fp6.Storage, second: Fp6.Storage) {
        let lowLevel = first.withUnsafeLowLevelAccess { f in
            second.withUnsafeLowLevelAccess { s in
                blst_fp12(fp6: (f.pointee, s.pointee))
            }
        }
        self.init(lowLevel: lowLevel)
    }
}


internal extension Fp12.Storage {
    static func ==(lhs: Fp12.Storage, rhs: Fp12.Storage) -> Bool {
        rhs.withUnsafeLowLevelAccess { r in
            lhs.withUnsafeLowLevelAccess { l in
                blst_fp12_is_equal(r, l)
            }
        }
    }
}

internal extension Fp12.Storage {
    @discardableResult
    func withUnsafeLowLevelAccess<R>(_ access: (UnsafeMutablePointer<LowLevel>) throws -> R) rethrows -> R {
        var lowLevel = self.lowLevel
        return try access(&lowLevel)
    }
}


internal extension Fp12.Storage {
    func isInGroup() -> Bool {
        withUnsafeLowLevelAccess {
            blst_fp12_in_group($0)
        }
    }
}
