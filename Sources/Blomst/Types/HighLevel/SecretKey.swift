//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import BLST
import Foundation

public struct SecretKey: Equatable, DataSerializable, DataRepresentable {
    private let scalar: Scalar
    
    internal init(scalar: Scalar) {
        self.scalar = scalar
    }
}

// MARK: Generate new
public extension SecretKey {
    init() throws {
        try self.init(data: SecureBytes(count: Self.byteCount))
    }
}

// MARK: DataRepresentable
public extension SecretKey {
    init<D>(data: D) throws where D : ContiguousBytes {
        
        // Validation
        try data.withUnsafeBytes { bytes in
            if bytes.count < Self.byteCount {
                throw Error.tooFewBytes(got: bytes.count)
            }
            if bytes.count > Self.byteCount {
                throw Error.tooManyBytes(got: bytes.count)
            }
            if bytes.allSatisfy({ $0 == 0x00 }) {
                throw Error.bytesAllZero
            }
        }
        
        let scalar = try Scalar(data: data)
        self.init(scalar: scalar)
    }
}

// MARK: DataSerializable
public extension SecretKey {
    func toData() -> Data {
        scalar.toData()
    }
}
    
public extension SecretKey {
    
    func publicKey() -> PublicKey {
        var p1 = blst_p1()
        scalar.withUnsafeLowLevelAccess { sk in
            blst_sk_to_pk_in_g1(&p1, sk)
        }
        return PublicKey(
            p1: .init(lowLevel: p1)
        )
    }
    
    func sign(
        message: Message,
        domainSeperationTag: DomainSeperationTag,
        augmentation: Augmentation = .init()
    ) throws -> Signature {
        domainSeperationTag.withUnsafeBytes { dstBytes in
            augmentation.withUnsafeBytes { augBytes in
                message.withUnsafeBytes { msgBytes in
                    var hash = blst_p2()
                    blst_hash_to_g2(
                        &hash,
                        msgBytes.baseAddress,
                        msgBytes.count,
                        dstBytes.baseAddress,
                        dstBytes.count,
                        augBytes.baseAddress,
                        augBytes.count
                    )
                    var outSig = blst_p2()
                    self.scalar.withUnsafeLowLevelAccess { sk in
                        blst_sign_pk_in_g1(&outSig, &hash, sk)
                    }
                    return Signature(p2: .init(lowLevel: outSig))
                }
            }
        }
    }
}

public extension SecretKey {
    static let byteCount = 32
}

public extension SecretKey {
    enum Error: Swift.Error, Equatable {
        case tooFewBytes(got: Int, expected: Int = SecretKey.byteCount)
        case tooManyBytes(got: Int, expected: Int = SecretKey.byteCount)
        case bytesAllZero
        case deserializeFromBytesFailed
    }
}
