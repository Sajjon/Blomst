//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation
import BLST

public enum Operation: Equatable {
    case hash
    case encode
}

private extension Operation {
    var isHash: Bool {
        switch self {
        case .hash: return true
        case .encode: return false
        }
    }
}

public struct Pairing {

    
    private let v: [UInt64]
    
    init(
        domainSeperationTag: DomainSeperationTag,
        operation: Operation
    ) {

        var v = [UInt64](
            repeating: 0,
            count: blst_pairing_sizeof() / 8
        )
        
        domainSeperationTag.withUnsafeBytes { dstBytes in
            v.withUnsafeMutableBytes { vBytes in
                blst_pairing_init(
                    OpaquePointer(vBytes.baseAddress),
                    operation.isHash, // "hash_or_encode"
                    dstBytes.baseAddress,
                    domainSeperationTag.bytes.count
                )

            }
        }
        
        self.v = v
    }
    

}


private extension Pairing {
    typealias Gt = Fp12
    static func _aggregatedInG2(signature: Signature) -> Gt {
        signature.p2.affine().withUnsafeLowLevelAccess { sig in
            var out = blst_fp12()
            blst_aggregated_in_g2(&out, sig)
            return Gt(lowLevel: out)
        }
    }
}

public extension Pairing {
    
    func commit() {
        self.v.withUnsafeBytes {
            let ctx = OpaquePointer($0.baseAddress)
            blst_pairing_commit(ctx)
        }
    }

    
    func finalVerify(signature: Signature) -> Bool {
        let gtSig = Pairing._aggregatedInG2(signature: signature)
        return gtSig.withUnsafeLowLevelAccess { gtsig in
            self.v.withUnsafeBytes {
                let ctx = OpaquePointer($0.baseAddress)
                return blst_pairing_finalverify(ctx, gtsig)
            }
        }
    }
    
    /// Check and aggregate PublicKey in `G1`
    func aggregatePublicKeyInG1(
        publicKey: PublicKey,
        signature: Signature?,
        message: Message,
        augmentation: Augmentation = .init(),
        checkGroupOfPublicKey: Bool,
        checkGroupOfSignatue: Bool
    ) throws {
        var wasPerformed = false
        try message.withUnsafeBytes { msgBytes in
            try publicKey.affine().withUnsafeLowLevelAccess { pubKeyLowLevel in
                try augmentation.withUnsafeBytes { augBytes in
                    try self.v.withUnsafeBytes { contextBytes in
                        let context = OpaquePointer(contextBytes.baseAddress!)
                        guard blst_pairing_chk_n_aggr_pk_in_g1(
                            context,
                            pubKeyLowLevel,
                            checkGroupOfPublicKey,
                            signature.map { $0.affine().storage.lowLevelPointer } ?? nil,
                            checkGroupOfSignatue,
                            msgBytes.bindMemory(to: UInt8.self).baseAddress!,
                            message.count,
                            augBytes.bindMemory(to: UInt8.self).baseAddress!,
                            augmentation.count
                        ) == BLST_SUCCESS else {
                            throw Error.failedToPair
                        }
                        wasPerformed = true
                    }
                }
            }
        }
        assert(wasPerformed)
        // All good
    }
    
    enum Error: Swift.Error {
        case failedToPair
    }
}
