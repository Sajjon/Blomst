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
public struct G2Affine: Equatable {
    internal let p2Affine: P2Affine
   
    init(p2Affine: P2Affine) throws {
        guard p2Affine.isElementInGroupG2() else {
            throw Error.notInGroup
        }
        self.p2Affine = p2Affine
    }
}

public extension G2Affine {
    enum Error: Swift.Error {
        case notInGroup
    }
}
