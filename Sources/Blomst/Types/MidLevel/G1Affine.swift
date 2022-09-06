//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-06.
//

import Foundation
import BLST

/// A wrapper of `BLS12-381` **affine** point, having two coordinates: `x, y`
/// guaranteed to be in the group `G1`.
public struct G1Affine: Equatable {
    internal let p1Affine: P1Affine
   
    init(p1Affine: P1Affine) throws {
        guard p1Affine.isElementInGroupG1() else {
            throw Error.notInGroup
        }
        self.p1Affine = p1Affine
    }
}

public extension G1Affine {
    enum Error: Swift.Error {
        case notInGroup
    }
}
