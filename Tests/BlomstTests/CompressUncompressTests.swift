//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-13.
//

import Foundation
import XCTest
import Blomst
import XCTAssertBytesEqual

/*
 public protocol PointComponentProtocol: AdditiveArithmetic {
     static var one: Self { get }
     static func * (lhs: Self, rhs: Self) -> Self
 }

 public protocol ProjectivePoint {
     
     associatedtype Component: PointComponentProtocol
     var x: Component { get }
     var y: Component { get }
     var z: Component { get }
     init(x: Component, y: Component, z: Component) throws
     
     associatedtype Affine: AffinePoint
     func affine() throws -> Affine
     static var generator: Self { get }
     static var identity: Self { get }
     static func +(lhs: Self, rhs: Self) -> Self
 }

 */


//struct PUREG1Projective: ProjectivePoint {}
//struct PUREG1Affine: AffinePoint {
//    typealias Component = Void
//    var x: Component { get }
//    var y: Component { get }
//    init(x: Component, y: Component) throws
//}

protocol IdentityOwner {
    static var identity: Self { get }
}
protocol GeneratorOwner {
    static var generator: Self { get }
}
protocol AffineConvertible {
    associatedtype Affine
    func affine() throws -> Affine
}
protocol Addable {
    static func + (lhs: Self, rhs: Self) -> Self
}

extension G1Projective: IdentityOwner {}
extension G1Projective: GeneratorOwner {}
extension G1Projective: AffineConvertible {}
extension G1Projective: Addable {}

final class CompressUncompressTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        DefaultXCTAssertBytesEqualParameters.haltOnPatternNonIdentical = true
    }
    
    func test_p1_addition() {
        let a = P1.generator
        let b = P1.generator
        XCTAssertNotEqual(a + b, a)
    }
    
    func test_fp1_addition_and_multiplication() {
        XCTAssertEqual(Fp1.one + Fp1.one, Fp1.one * 2)
    }
    
    func test_fp1_addition_with_zero() {
        XCTAssertEqual(Fp1.one + Fp1.zero, Fp1.one)
    }
    
    func test_p1_identity_is_zero_one_zero() throws {
        print("one: \(try Fp1.one.uncompressedData().hex)")
        XCTAssertEqual(
            try Fp1.one.uncompressedData().hex,
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
        )
        
    }
    
    func test_g1_uncompressed() throws {
        
        try elementOnCurveTest(
            name: "g1_uncompressed_valid_test_vectors",
            projectiveType: G1Projective.self,
            serializeAffine: { try $0.uncompressedData() },
            deserializeAffine: G1Affine.init(uncompressedData:)
        )
    }
    
    //    func test_g1_uncompressed_PURE_C() throws {
    //
    //        try elementOnCurveTest(
    //            name: "g1_uncompressed_valid_test_vectors",
    //            projectiveType: PUREG1Projective.self,
    //            serializeAffine: { try $0.uncompressedData() },
    //            deserializeAffine: PUREG1Affine.init(uncompressedData:)
    //        )
    //    }
}

typealias SUT = ProjectivePoint
//typealias SUT = GeneratorOwner & IdentityOwner & AffineConvertible & Addable
extension CompressUncompressTests {
    func elementOnCurveTest<Projective>(
        name: String,
        projectiveType: Projective.Type,
        serializeAffine: (Projective.Affine) throws -> Data,
        deserializeAffine: (Data) throws -> Projective.Affine,
        line: UInt = #line
    ) throws where Projective: SUT, Projective.Affine: Equatable {
        try doTestDATFixture(name: name, line: line) { suiteData in
            XCTAssertGreaterThanOrEqual(suiteData.count, 48000, line: line)
            var e = Projective.identity
            var v: Data = .init()
            var expected = suiteData
            for index in 0..<1000 {
                if index < 4 {
                    print("\nv: \"\(v.hex)\"")
                }
                let e_affine = try e.affine()
                if index < 4 {
                    print("\ne_affine: \(e_affine)")
                }
                let encoded = try serializeAffine(e_affine)
                v.append(encoded)
                let decoded = encoded
                let encodingByteCount = decoded.count
//                decoded += expected.prefix(encodingByteCount)
                if index < 4 {
                    print("\ndecoded: \"\(decoded.hex)\"")
                }
                expected.removeFirst(encodingByteCount)
                if index < 4 {
                    print("\nexpected.count: \(expected.count)")
                }
                let affineFromDecoded = try deserializeAffine(decoded)
                XCTAssertEqual(affineFromDecoded, e_affine, line: line)
                if index < 4 {
                    print("\ne: \(e)")
                }
                e = e + Projective.generator
            }
            print("suiteData.count: \(suiteData.count)")
            XCTAssertGreaterThanOrEqual(suiteData.count, 48000, line: line)
            print("expected.count: \(expected.count)")
            print("v.count: \(v.count)")
            XCTAssertBytesEqual(v, suiteData, line: line)
        }
    }
}
