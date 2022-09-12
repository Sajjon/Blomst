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
public struct G1Affine: Equatable, CustomStringConvertible {
    public var description: String {
        """
        P1Affine(
            x: \(x)
            y: \(y)
        )
        """
    }
    internal let p1Affine: P1Affine
   
    init(p1Affine: P1Affine) throws {
        guard p1Affine.isElementInGroupG1() else {
            throw Error.notInGroup
        }
        self.p1Affine = p1Affine
    }
    
    init(p1: P1) throws {
        try self.init(p1Affine: p1.affine())
    }
    
    init(lowLevel: P1.Storage.LowLevel) throws {
        let p1 = P1(lowLevel: lowLevel)
        try self.init(p1: p1)
    }
    
    public init(x: Fp1, y: Fp1) throws {
        try self.init(p1Affine: P1Affine(x: x, y: y))
    }
}

public extension G1Affine {
    var x: Fp1 {
        p1Affine.x
    }
    var y: Fp1 {
        p1Affine.y
    }
}

public extension G1Affine {
    enum Error: Swift.Error {
        case notInGroup
    }
}
