//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation
import BLST


public struct PublicKey: Equatable, UncompressedDataSerializable, CompressedDataSerializable {
    
    internal let p1: P1
    
    internal init(p1: P1) {
        self.p1 = p1
    }
}

public extension PublicKey {
    typealias Affine = P1.Affine
    func affine() -> Affine {
        p1.affine()
    }
}

// MARK: UncompressedDataSerializable
public extension PublicKey {
    
    /// Uncompressed publickey
    func uncompressedData() throws -> Data {
        try p1.uncompressedData()
    }
}

// MARK: CompressedDataSerializable
public extension PublicKey {
    func compressedData() throws -> Data {
        var data = Data(repeating: 0x00, count: 48)
        data.withUnsafeMutableBytes { outBytes in
            p1.withUnsafeLowLevelAccess {
                blst_p1_compress(outBytes.baseAddress, $0)
            }
        }
        return data
    }
}
