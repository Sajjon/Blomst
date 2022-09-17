//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation
import BLST

public struct Signature: Equatable, UncompressedDataSerializable {
    
    public let p2: P2
    
    internal init(p2: P2) {
        self.p2 = p2
    }
    
}

public extension Signature {
    typealias Affine = P2.Affine
   
    func affine() -> Affine {
        p2.affine()
    }
}

// MARK: UncompressedDataSerializable
public extension Signature {
    func uncompressedData() throws -> Data {
        try p2.uncompressedData()
    }
}


public extension Signature {
    /*
    func hashBasedVerify(
        hashFn: (Message, DomainSeperationTag, Augmentation) throws -> HashOf<G2Projective>,
        message: Message,
        domainSeperationTag: DomainSeperationTag,
        augmentation: Augmentation = .init(),
        publicKey: PublicKey
    ) async throws -> Bool {
        try await hashBasedVerify(
            hashes: [hashFn(message, domainSeperationTag, augmentation)],
            publicKeys: [publicKey]
        )
    }
    
    func hashBasedVerify(
        hash: HashOf<G2Projective>,
        publicKey: PublicKey
    ) async throws -> Bool {
        try await hashBasedVerify(hashes: [hash], publicKeys: [publicKey])
    }
    
    func hashBasedVerify(
        hashes: [HashOf<G2Projective>],
        publicKeys: [PublicKey]
    ) async throws -> Bool {
        guard !hashes.isEmpty else {
            return false
        }
        guard !publicKeys.isEmpty else {
            return false
        }
        guard hashes.count == publicKeys.count else {
            return false
        }
        
        // Enforce that messages are distinct as a countermeasure against BLS's rogue-key attack.
          // See Section 3.1. of the IRTF's BLS signatures spec:
          // https://tools.ietf.org/html/draft-irtf-cfrg-bls-signature-02#section-3.1
        let count = hashes.count
          for i in 0..<count {
              for j in (i + 1)..<count {
                  print("i: \(i), j: \(j)")
                  if hashes[i] == hashes[j] {
                      return false
                  }
              }
          }
        
        var isValid = true
        var miller = try zip(publicKeys, hashes)
            .map { (publicKey, hash) -> Fp12 in
                try! print("\n\nhash projective: \(hash.element.p2.uncompressedData().hex)")
                try! print("hash projective.x.real.uncompressed: \(hash.element.x.real.uncompressedData().hex)")
                try! print("hash projective.x.img.uncompressed: \(hash.element.x.imaginary.uncompressedData().hex)")
                
                try! print("hash projective.y.real.uncompressed: \(hash.element.y.real.uncompressedData().hex)")
                try! print("hash projective.y.img.uncompressed: \(hash.element.y.imaginary.uncompressedData().hex)")
                
                
                try! print("hash projective.z.real.uncompressed: \(hash.element.z.real.uncompressedData().hex)")
                try! print("hash projective.z.img.uncompressed: \(hash.element.z.imaginary.uncompressedData().hex)")
                
                let pkProjective = try publicKey.projective()
                if pkProjective.isIdentity {
                    isValid = false
                }
                let pkAffine = publicKey.affine()
                let h = hash.element.affine()
                try! print("\n\nhash affine uncompressedData: \(h.uncompressedData().hex)")
                try! print("\n\npublicKey affine uncompressed: \(pkAffine.uncompressedData().hex)")
                try! print("\n\npublicKey affine compressed: \(pkAffine.compressedData().hex)")
                
                let millerInner = pkAffine.withUnsafeLowLevelAccess { p1Aff in
                    h.p2Affine.withUnsafeLowLevelAccess { p2Aff in
                        var out = blst_fp12()
                        blst_miller_loop(&out, p2Aff, p1Aff)
                        return Fp12(lowLevel: out)
                    }
                }
                
                try print("\n\nmillerInner.first.first.real.uncompressed: \(millerInner.first.first.real.uncompressedData().hex)")
                try print("\n\nmillerInner.first.first.imaginary.uncompressed: \(millerInner.first.first.imaginary.uncompressedData().hex)")
                try print("\n\nmillerInner.first.second.real.uncompressed: \(millerInner.first.second.real.uncompressedData().hex)")
                try print("\n\nmillerInner.first.second.imaginary.uncompressed: \(millerInner.first.second.imaginary.uncompressedData().hex)")
                try print("\n\nmillerInner.first.third.real.uncompressed: \(millerInner.first.third.real.uncompressedData().hex)")
                try print("\n\nmillerInner.first.third.imaginary.uncompressed: \(millerInner.first.third.imaginary.uncompressedData().hex)")
                
                try print("\n\nmillerInner.second.first.real.uncompressed: \(millerInner.second.first.real.uncompressedData().hex)")
                try print("\n\nmillerInner.second.first.imaginary.uncompressed: \(millerInner.second.first.imaginary.uncompressedData().hex)")
                try print("\n\nmillerInner.second.second.real.uncompressed: \(millerInner.second.second.real.uncompressedData().hex)")
                try print("\n\nmillerInner.second.second.imaginary.uncompressed: \(millerInner.second.second.imaginary.uncompressedData().hex)")
                try print("\n\nmillerInner.second.third.real.uncompressed: \(millerInner.second.third.real.uncompressedData().hex)")
                try print("\n\nmillerInner.second.third.imaginary.uncompressed: \(millerInner.second.third.imaginary.uncompressedData().hex)")
                
           
          
                
                try print("\n\nmillerInner.first.first.uncompressed: \(millerInner.first.first.uncompressedData().hex)")
                try print("\n\nmillerInner.first.second.uncompressed: \(millerInner.first.second.uncompressedData().hex)")
                try print("\n\nmillerInner.first.third.uncompressed: \(millerInner.first.third.uncompressedData().hex)")
                
                try print("\n\nmillerInner.second.first.uncompressed: \(millerInner.second.first.uncompressedData().hex)")
                try print("\n\nmillerInner.second.second.uncompressed: \(millerInner.second.second.uncompressedData().hex)")
                try print("\n\nmillerInner.second.third.uncompressed: \(millerInner.second.third.uncompressedData().hex)")
                return millerInner
            }
            .reduce(Fp12.one) { acc, cur in acc * cur }
        
        guard isValid else {
            return false
        }
        
        let g1Neg = try G1Affine.generator.negated()
        let g1NegMiller: Fp12 = {
            return g1Neg.p1Affine.withUnsafeLowLevelAccess { p1Aff in
                self.p2.affine().withUnsafeLowLevelAccess { p2Aff in
                    var out = blst_fp12()
                    blst_miller_loop(&out, p2Aff, p1Aff)
                    return Fp12(lowLevel: out)
                }
            }
        }()
        miller = miller * g1NegMiller
        let targetGroupIdentity = Fp12.one // Gt.identity

        return targetGroupIdentity.withUnsafeLowLevelAccess { gt1 in
            miller.withUnsafeLowLevelAccess { gt2 in
                blst_fp12_finalverify(gt1, gt2)
            }
        }
        
       
    }
    */
    
    func verify(
        publicKey: PublicKey,
        message: Message,
        domainSeperationTag: DomainSeperationTag = .G2,
        augmentation: Augmentation = .init(),
        groupCheck: Bool = true
    ) async throws -> Bool {
        let augMsg = augmentation + message
        
        return try await aggregateVerify(
            publicKeys: [publicKey],
            messages: [augMsg],
            domainSeperationTag: domainSeperationTag,
            groupCheck: groupCheck
        )
    }
    
    enum Error: Swift.Error, Equatable {
        case publicKeysEmpty
        case publicKeysAndMessageCountMismatch
        case invalid
    }
    
    func aggregateVerify(
        publicKeys: [PublicKey],
        messages: [Message],
        domainSeperationTag: DomainSeperationTag,
        groupCheck: Bool = true
    ) async throws -> Bool {
       
        guard !publicKeys.isEmpty else {
            throw Error.publicKeysEmpty
        }
       
        guard publicKeys.count == messages.count else {
            throw Error.publicKeysAndMessageCountMismatch
        }
        
        guard MessagesUniqueValidator.validator(messages: messages) else {
            return false
        }
        
        let pairing = Pairing(
            domainSeperationTag: domainSeperationTag,
            operation: .hash
        )
        
        let isValid = try await withThrowingTaskGroup(of: Bool.self) { group in
            for index in 0..<publicKeys.count {
                group.addTask {
                    let publicKey = publicKeys[index]
                    let message = messages[index]

                    do {
                        try pairing.aggregatePublicKeyInG1(
                            publicKey: publicKey,
                            signature: nil,
                            message: message,
                            augmentation: .init(),
                            checkGroupOfPublicKey: true,
                            checkGroupOfSignatue: true
                        )
                    } catch {
                        return false
                    }
                    
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

        return pairing.finalVerify(signature: self)
  
    }
}

