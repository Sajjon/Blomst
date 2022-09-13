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

final class CompressUncompressTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func test_p1_addition() {
        let a = P1.generator
        let b = P1.generator
        let sum = a + b
        print("a: \(a)")
        print("b: \(b)")
        print("sum: \(sum)")
        XCTAssertNotEqual(sum, a)
    }
    
    func test_p1_generator() throws {
        let xData = try Data(hex: "1144f72e5d8a469db166f58521e70676db2c6defa37e40da314436a0645f2511037bf2f1a83aa341bafe74514c615fae")
        let yData = try Data(hex: "064a3a594868a2a4dab071ff6d880ae0f459c87e11ab01b3454b95a7d6a93f853f6e07f754b6e7933799e0afe2779a56")
        let zData = try Data(hex: "08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1")
        let x = try Fp1(uncompressedData: xData)
        let y = try Fp1(uncompressedData: yData)
        let z = try Fp1(uncompressedData: zData)
        
//        let expected = P1(
//            x: x,
//            y: y,
//            z: z
//        )
//        XCTAssertEqual(expected, .generator)
    }
    
    func test_fp1_addition_and_multiplication() {
        XCTAssertEqual(Fp1.one + Fp1.one, Fp1.one * 2)
    }
    func test_fp1_addition_with_zero() {
        XCTAssertEqual(Fp1.one + Fp1.zero, Fp1.one)
    }
    
    func test_g1_uncompressed() throws {
        try elementOnCurveTest(
            name: "g1_uncompressed_valid_test_vectors",
            projectiveType: G1Projective.self,
            serializeAffine: { try $0.uncompressedData() },
            deserializeAffine: G1Affine.init(uncompressedData:)
        )
    }
    func test_g1_compressed() throws {
        try elementOnCurveTest(
            name: "g1_compressed_valid_test_vectors",
            projectiveType: G1Projective.self,
            serializeAffine: { try $0.compressedData() },
            deserializeAffine: G1Affine.init(compressedData:)
        )
    }
    
    func elementOnCurveTest<Projective>(
        name: String,
        projectiveType: Projective.Type,
        serializeAffine: (Projective.Affine) throws -> Data,
        deserializeAffine: (Data) throws -> Projective.Affine,
        line: UInt = #line
    ) throws where Projective: ProjectivePoint, Projective.Affine: Equatable {
        try doTestDATFixture(name: name, line: line) { suiteData in
            XCTAssertGreaterThanOrEqual(suiteData.count, 48000, line: line)
            var e = Projective.identity
            var v: Data = .init()
            var expected = suiteData
            for _ in 0..<1000 {
                let e_affine = try e.affine()
                let encoded = try serializeAffine(e_affine)
                v.append(encoded)
                var decoded = encoded
                let encodingByteCount = decoded.count
                decoded += expected.prefix(encodingByteCount)
                expected.removeFirst(encodingByteCount)
                let affineFromDecoded = try deserializeAffine(decoded)
                XCTAssertEqual(affineFromDecoded, e_affine, line: line)
                print("e before: \(e), generator: \(Projective.generator)")
                e = e + Projective.generator
                print("e after: \(e)")
            }
            print("suiteData.count: \(suiteData.count)")
            XCTAssertGreaterThanOrEqual(suiteData.count, 48000, line: line)
            print("expected.count: \(expected.count)")
            print("v.count: \(v.count)")
            XCTAssertBytesEqual(v, suiteData, line: line)
        }
    }
}
