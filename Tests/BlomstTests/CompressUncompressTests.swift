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

@MainActor
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
    
    func skip_test_g1_uncompressed() async throws {
        
        try await elementOnCurveTest(
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

extension CompressUncompressTests {
    
    @MainActor
    func elementOnCurveTest<Projective>(
        name: String,
        projectiveType: Projective.Type,
        serializeAffine: @escaping (Projective.Affine) throws -> Data,
        deserializeAffine: @escaping (Data) throws -> Projective.Affine,
        line: UInt = #line
    ) async throws where Projective: ProjectivePoint, Projective.Affine: Equatable {
        try await doTestDATFixture(name: name, line: line) { suiteData in
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
            XCTAssertEqual(v.count, suiteData.count, line: line)

            // TEMP DEBUGING COMPARE BELOW
            var offset = 0
            while offset < suiteData.count {
                let sliceLen = 32
                let vSlice = v[offset..<offset+sliceLen]
                let suiteDataSlice = suiteData[offset..<offset+sliceLen]
                XCTAssertBytesEqual(vSlice, suiteDataSlice, "Slice at: \(offset)", line: line)
                offset += sliceLen
            }
//            XCTAssertBytesEqual(v, suiteData)//, line: line)
        }
    }
}
