//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation
import CryptoKit
import BLST
import BytePattern

public struct SecretKey: Equatable, UncompressedDataSerializable, UncompressedDataRepresentable {
    private let scalar: Scalar
    
    internal init(scalar: Scalar) {
        self.scalar = scalar
    }
}


public extension SecretKey {
    init<D>(inputKeyMaterial: D) throws where D: ContiguousBytes {
        let hk = HKDF<SHA256>.extract(
            inputKeyMaterial: .init(data: inputKeyMaterial),
            salt: Self.salt
        )
        let okm = hk.withUnsafeBytes {
            HKDF<SHA256>.expand(
                pseudoRandomKey: $0,
                info: Data(),
                outputByteCount: Self.byteCount
            )
        }

        self = try okm.withUnsafeBytes {
            try Self.init(uncompressedData: $0)
        }
    }
}

// MARK: Generate new
public extension SecretKey {
    init() throws {
        try self.init(uncompressedData: SecureBytes(count: Self.byteCount))
    }
}

// MARK: UncompressedDataRepresentable
public extension SecretKey {
    init(uncompressedData: some ContiguousBytes) throws {
        
        // Validation
        try uncompressedData.withUnsafeBytes { bytes in
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
        
        let scalar = try Scalar(uncompressedData: uncompressedData)
        self.init(scalar: scalar)
    }
}

// MARK: UncompressedDataSerializable
public extension SecretKey {
    func uncompressedData() throws -> Data {
        try scalar.uncompressedData()
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
    /// given by ceil((1.5 * ceil(log2(r))) / 8).
    static let byteCount = 48
    
    static let salt = "BLS-SIG-KEYGEN-SALT-".data(using: .utf8)!
}

public extension SecretKey {
    enum Error: Swift.Error, Equatable {
        case tooFewBytes(got: Int, expected: Int = SecretKey.byteCount)
        case tooManyBytes(got: Int, expected: Int = SecretKey.byteCount)
        case bytesAllZero
        case deserializeFromBytesFailed
    }
}
