//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation
import BLST


public struct PublicKey: Equatable, DataSerializable, AffineSerializable {
    
    internal let p1: P1
    
    internal init(p1: P1) {
        self.p1 = p1
    }
}

// MARK: AffineSerializable
public extension PublicKey {
    typealias Affine = P1.Affine
    func affine() -> Affine {
        p1.affine()
    }
}

// MARK: DataSerializable
public extension PublicKey {
    
    /// Uncompressed publickey
    func toData() -> Data {
        p1.toData()
    }
    
    func compressedData() -> Data {
        var data = Data(repeating: 0x00, count: 48)
        data.withUnsafeMutableBytes { outBytes in
            p1.withUnsafeLowLevelAccess {
                blst_p1_compress(outBytes.baseAddress, $0)
            }
        }
        return data
    }
}
