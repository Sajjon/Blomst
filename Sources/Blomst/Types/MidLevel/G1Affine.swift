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
public struct G1Affine:
    Equatable,
    CustomStringConvertible,
    UncompressedDataSerializable,
    UncompressedDataRepresentable,
    CompressedDataSerializable,
    CompressedDataRepresentable,
    AffinePoint
{
    
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
    
    public typealias Component = Fp1
    
    public init(x: Fp1, y: Fp1) throws {
        try self.init(p1Affine: P1Affine(x: x, y: y))
    }
    
    public init(projective: G1Projective) throws {
        try self.init(p1Affine: projective.p1.affine())
    }
}

public extension G1Affine {
    
    func compressedData() throws -> Data {
        let compressed = try p1Affine.compressedData()
        assert(compressed.data.count == 48)
        return compressed
    }
    
    /// Serializes this element into uncompressed form.
    func uncompressedData() throws -> Data {
        let data = try p1Affine.uncompressedData()
        assert(data.count == 96)
        return data
    }
    
    var x: Fp1 {
        p1Affine.x
    }
    var y: Fp1 {
        p1Affine.y
    }
    
    var isInfinity: Bool {
        p1Affine.isInfinity
    }
    
    static let generator = try! Self(p1: .generator)
    
    func negated() throws -> Self {
        //        //        y: Fp::conditional_select(&-self.y, &Fp::one(), self.infinity),
        //                y: isInfinity ? blst_fp_cneg(<#T##ret: UnsafeMutablePointer<blst_fp>!##UnsafeMutablePointer<blst_fp>!#>, <#T##a: UnsafePointer<blst_fp>!##UnsafePointer<blst_fp>!#>, <#T##flag: Bool##Bool#>)
        let conditionalY: Fp1 = {
            var out = blst_fp()
            y.withUnsafeLowLevelAccess { fp in
                blst_fp_cneg(&out, fp, self.isInfinity)
            }
            return Fp1.init(lowLevel: out)
        }()
        
        return try Self(
            x: self.x,
            y: conditionalY
            //                 infinity: self.infinity,
        )
    }
    
    /// From uncompressed data
    init(uncompressedData: some ContiguousBytes) throws {
        try self.init(p1Affine: .init(uncompressedData: uncompressedData))
    }
    
    init(compressedData: some ContiguousBytes) throws {
        try self.init(p1Affine: .init(compressedData: compressedData))
    }
    
}

public extension G1Affine {
    enum Error: Swift.Error {
        case notInGroup
    }
}
