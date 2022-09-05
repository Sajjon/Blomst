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
    func toData() -> Data {
        p1.toData()
    }
}
