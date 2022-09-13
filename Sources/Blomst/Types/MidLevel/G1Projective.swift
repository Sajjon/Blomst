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
public struct G1Projective: Equatable {
    internal let p1: P1
   
    init(p1: P1) throws {
        guard p1.isElementInGroupG1() else {
            throw Error.notInGroup
        }
        self.p1 = p1
    }
}

public extension G1Projective {
    enum Error: Swift.Error {
        case notInGroup
    }
}
