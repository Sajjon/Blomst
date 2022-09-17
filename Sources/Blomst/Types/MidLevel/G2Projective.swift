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
public struct G2Projective: Equatable, ProjectivePoint, CompressedDataRepresentable {
    internal let p2: P2
   
    init(p2: P2) throws {
        guard p2.isElementInGroupG2() else {
            throw Error.notInGroup
        }
        self.p2 = p2
    }
    public init(compressedData: some ContiguousBytes) throws {
        try self.init(p2: .init(compressedData: compressedData))
    }
    
    init(lowLevel: P2.Storage.LowLevel) throws {
        try self.init(p2: .init(storage: .init(lowLevel: lowLevel)))
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

public extension G2Projective {
    typealias Component = P2.Component
    var x: Component {
        p2.x
    }
    var y: Component {
        p2.y
    }
    var z: Component {
        p2.z
    }
    init(x: Component, y: Component, z: Component) throws {
        try self.init(p2: .init(x: x, y: y, z: z))
    }
    static var generator: Self {
        try! .init(p2: .generator)
    }
    static var identity: Self {
        try! self.init(p2: .identity)
    }
    static func +(lhs: Self, rhs: Self) -> Self {
        try! self.init(p2: lhs.p2 + rhs.p2)
    }
}
