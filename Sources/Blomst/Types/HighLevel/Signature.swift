//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation
import BLST

public struct Signature: Equatable, DataSerializable, AffineSerializable {
    
    private let p2: P2
    
    internal init(p2: P2) {
        self.p2 = p2
    }
    
}

// MARK: AffineSerializable
public extension Signature {
    typealias Affine = P2.Affine
   
    func affine() -> Affine {
        p2.affine()
    }
}

// MARK: DataSerializable
public extension Signature {
    func toData() -> Data {
        p2.toData()
    }
}

public extension Signature {
    
    func verify(
        groupCheck: Bool,
        message: Message,
        domainSeperationTag: DomainSeperationTag,
        augmentation: Augmentation = .init(),
        publicKey: PublicKey
    ) async throws {
        let augMsg = augmentation + message
        
        try await aggregateVerify(
            groupCheck: groupCheck,
            messages: [augMsg],
            domainSeperationTag: domainSeperationTag,
            publicKeys: [publicKey]
        )
    }
    
    enum Error: Swift.Error, Equatable {
        case publicKeysEmpty
        case publicKeysAndMessageCountMismatch
        case invalid
    }
    
    func aggregateVerify(
        groupCheck: Bool,
        messages: [Message],
        domainSeperationTag: DomainSeperationTag,
        publicKeys: [PublicKey]
    ) async throws {
       
        guard !publicKeys.isEmpty else {
            throw Error.publicKeysEmpty
        }
       
        guard publicKeys.count == messages.count else {
            throw Error.publicKeysAndMessageCountMismatch
        }
        
        // TODO - check msg uniqueness?
        let isValid = try await withThrowingTaskGroup(of: Bool.self) { group in
            for index in 0..<publicKeys.count {
                group.addTask {
                    let pairing = Pairing(
                        domainSeperationTag: domainSeperationTag,
                        hashOrEncode: true
                    )
                    
                    let publicKey = publicKeys[index]
                    let message = messages[index]
                    
                    try pairing.aggregatePublicKeyInG1(
                        publicKey: publicKey,
                        signature: self,
                        message: message,
                        augmentation: Augmentation(),
                        checkGroupOfPublicKey: false,
                        checkGroupOfSignatue: true
                    )
                    
                    pairing.commit()
                    
                    return true
                }
            }
            
            return try await group.reduce(into: true) { agg, taskResult in
                agg = agg && taskResult
            }
        }
        guard isValid else {
            throw Error.invalid
        }
        // All good
    }
}
