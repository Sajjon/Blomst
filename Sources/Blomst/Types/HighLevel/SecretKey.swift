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
import BigInt

public struct SecretKey:
    Equatable,
    DataSerializable,
    DataRepresentable
{
    private let scalar: Scalar
    
    public init(scalar: Scalar) {
        self.scalar = scalar
    }
  
}

public extension SecretKey {
    init(decimalString: String) throws {
        guard let int = BigUInt(decimalString, radix: 10) else {
            throw Error.invalidDecimalString
        }
        let data = int.serialize()
        let scalar = try Scalar(data: data)
        self.init(scalar: scalar)
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
            try Self.init(data: $0)
        }
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
    init(data: some ContiguousBytes) throws {
        
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
    func data() throws -> Data {
        try scalar.data()
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
        domainSeperationTag: DomainSeperationTag = .G2,
        augmentation: Augmentation = .init()
    ) throws -> Signature {
        let hashAffine = try hashToG2(
            message: message,
            domainSeperationTag: domainSeperationTag,
            augmentation: augmentation
        )
        let hash = hashAffine.element.p2
        var outSig = blst_p2()
     
        self.scalar.withUnsafeLowLevelAccess { sk in
            hash.withUnsafeLowLevelAccess { hsh in
                blst_sign_pk_in_g1(&outSig, hsh, sk)
            }
        }
        
        return Signature(p2: .init(lowLevel: outSig))
      
    }
}

#if DEBUG
public extension SecretKey {
    
    func sign(
        _ message: String,
        domainSeperationTag: DomainSeperationTag = .G2,
        augmentation: Augmentation = .init()
    ) throws -> Signature {
        try sign(
            message: message.data(using: .utf8)!,
            domainSeperationTag: domainSeperationTag,
            augmentation: augmentation
        )
    }
}
#endif // DEBUG

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
        case invalidDecimalString
    }
}

#if DEBUG
extension SecretKey: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral mostSignigicantInt: IntegerLiteralType) {
        self.init(scalar: .init(integerLiteral: mostSignigicantInt))
    }
}

#endif // DEBUG
