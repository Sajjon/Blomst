//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation
import BLST

public struct Pairing {

    
    private let v: [UInt64]
    
    init(
        domainSeperationTag: DomainSeperationTag,
        hashOrEncode: Bool
    ) {

        var v = [UInt64](
            repeating: 0,
            count: blst_pairing_sizeof() / 8
        )
        
        domainSeperationTag.withUnsafeBytes { dstBytes in
            v.withUnsafeMutableBytes { vBytes in
                blst_pairing_init(
                    OpaquePointer(vBytes.baseAddress),
                    hashOrEncode,
                    dstBytes.baseAddress,
                    domainSeperationTag.bytes.count
                )

            }
        }
        
        self.v = v
    }
    

}

public extension Pairing {
    
    func commit() {
        self.v.withUnsafeBytes {
            let ctx = OpaquePointer($0.baseAddress)
            blst_pairing_commit(ctx)
        }
    }
    
    /// Check and aggregate PublicKey in `G1`
    func aggregatePublicKeyInG1(
        publicKey: PublicKey,
        signature: Signature,
        message: Message,
        augmentation: Augmentation,
        checkGroupOfPublicKey: Bool,
        checkGroupOfSignatue: Bool
    ) throws {
        try publicKey.affine().withUnsafeLowLevelAccess { pubKey in
            try signature.affine().withUnsafeLowLevelAccess { sig in
                try self.v.withUnsafeBytes {
                    let ctx = OpaquePointer($0.baseAddress)
                    try message.withUnsafeBytes { msgBytes in
                        var msgBase = OpaquePointer(msgBytes.baseAddress)
                        try augmentation.withUnsafeBytes { augBytes in
                            var augBase = OpaquePointer(augBytes.baseAddress)

                            guard blst_pairing_chk_n_aggr_pk_in_g1(
                                ctx,
                                pubKey,
                                checkGroupOfPublicKey,
                                sig,
                                checkGroupOfSignatue,
                                &msgBase,
                                message.count,
                                &augBase,
                                augmentation.count
                            ) == BLST_SUCCESS else {
                                throw Error.failedToPair
                            }
                        }
                    }
                }
            }
        }
        
        // All good
    }
    
    enum Error: Swift.Error {
        case failedToPair
    }
}
