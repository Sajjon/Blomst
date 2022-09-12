//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` **affine** point, having two coordinates: `x, y`
/// guaranteed to be in the group `G2`.
public struct G2Affine: Equatable, DataSerializable {
    internal let p2Affine: P2Affine
   
    init(p2Affine: P2Affine) throws {
        guard p2Affine.isElementInGroupG2() else {
            throw Error.notInGroup
        }
        self.p2Affine = p2Affine
    }
    
    init(p2: P2) throws {
        try self.init(p2Affine: p2.affine())
    }
}

public extension G2Affine {
    init(x: Fp2, y: Fp2) throws {
        try self.init(p2Affine: .init(x: x, y: y))
    }
}

public extension G2Affine {
    func toData() -> Data {
        p2Affine.toData()
    }
}

public extension G2Affine {
    var x: Fp2 {
        p2Affine.x
    }
    
    var y: Fp2 {
        p2Affine.y
    }
}


public extension G2Affine {
    enum Error: Swift.Error {
        case notInGroup
    }
}
