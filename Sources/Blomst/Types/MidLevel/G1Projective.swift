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
public struct G1Projective: Equatable, ProjectivePoint, CustomStringConvertible, CompressedDataRepresentable {
    internal let p1: P1
   
    init(p1: P1) throws {
        guard p1.isElementInGroupG1() else {
            throw Error.notInGroup
        }
        self.p1 = p1
    }
    
    public init(compressedData: some ContiguousBytes) throws {
        try self.init(p1: .init(compressedData: compressedData))
    }
    
    init(lowLevel: P1.Storage.LowLevel) throws {
        try self.init(p1: .init(storage: .init(lowLevel: lowLevel)))
    }
}

public extension G1Projective {
    enum Error: Swift.Error {
        case notInGroup
    }
    
    var description: String {
        String(describing: p1)
    }
}




public extension G1Projective {
    
    typealias Component = Fp1
    var x: Component { p1.x }
    var y: Component { p1.y }
    var z: Component { p1.z }
    init(x: Component, y: Component, z: Component) throws {
        try self.init(p1: .init(x: x, y: y, z: z))
    }
    
    func affine() throws -> G1Affine {
        try G1Affine(p1Affine: p1.affine())
    }
    
    typealias Affine = G1Affine

    static func + (lhs: Self, rhs: Self) -> Self {
        try! self.init(p1: lhs.p1 + rhs.p1)
    }
    
    /// Returns true if this element is the identity (the point at infinity).
    var isIdentity: Bool {
        if z == .zero {
            assert(self == Self.identity)
            return true
        } else {
            assert(self != Self.identity)
            return false
        }
    }
    
    /// Returns the identity of the group: the point at infinity.
    static var identity: Self {
        try! Self(
            x: .zero,
            y: .one,
            z: .zero
        )
    }
    
    static var generator: Self {
//        /// Returns a fixed generator of the group. See [`notes::design`](notes/design/index.html#fixed-generators)
//         /// for how this generator is chosen.
//         pub fn generator() -> G1Projective {
//             G1Projective {
//                 x: Fp::from_raw_unchecked([
//                     0x5cb3_8790_fd53_0c16,
//                     0x7817_fc67_9976_fff5,
//                     0x154f_95c7_143b_a1c1,
//                     0xf0ae_6acd_f3d0_e747,
//                     0xedce_6ecc_21db_f440,
//                     0x1201_7741_9e0b_fb75,
//                 ]),
//                 y: Fp::from_raw_unchecked([
//                     0xbaac_93d5_0ce7_2271,
//                     0x8c22_631a_7918_fd8e,
//                     0xdd59_5f13_5707_25ce,
//                     0x51ac_5829_5040_5194,
//                     0x0e1c_8c3f_ad00_59c0,
//                     0x0bbc_3efc_5008_a26a,
//                 ]),
//                 z: Fp::one(),
//             }
//         }
//        fatalError()
        try! self.init(p1: .generator)
    }
    
}
