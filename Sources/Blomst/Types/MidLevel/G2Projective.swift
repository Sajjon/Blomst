//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` **projective** point, having three coordinates: `x, y, z`,
/// guaranteed to be in the group `G1`.
public struct G2Projective: Equatable {
    internal let p2: P2
   
    init(p2: P2) throws {
        guard p2.isElementInGroupG2() else {
            throw Error.notInGroup
        }
        self.p2 = p2
    }
}

public extension G2Projective {
    func affine() -> G2Affine {
        try! .init(p2Affine: p2.affine())
    }
}

public extension G2Projective {
    enum Error: Swift.Error {
        case notInGroup
    }
}
