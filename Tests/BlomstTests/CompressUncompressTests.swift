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
    func test_g1_uncompressed() throws {
        try elementOnCurveTest(
            name: "g1_uncompressed_valid_test_vectors",
            projectiveType: G1Projective.self
        )
    }
    func elementOnCurveTest<Projective>(
        name: String,
        projectiveType: Projective.Type,
        line: UInt = #line
    ) throws where Projective: ProjectivePoint, Projective.Affine: CompressedDataSerializable & UncompressedDataSerializable & UncompressedDataRepresentable & Equatable {
        try doTestDATFixture(name: name, line: line) { suiteData in
            XCTAssertEqual(suiteData.count, 96000, line: line)
            var e = Projective.identity
            var v: Data = .init()
            var expected = suiteData
            for _ in 0..<1000 {
                let e_affine = try e.affine() //try G1Affine(projective: e)
                let encoded = try e_affine.uncompressedData() /* serialize */
                v.append(encoded)
                var decoded = encoded
                let len_of_encoding = decoded.count
                decoded += expected.prefix(len_of_encoding)
                expected.removeFirst(len_of_encoding)
                let affineFromDecoded = try Projective.Affine(uncompressedData: decoded) /* deserialize */
                XCTAssertEqual(affineFromDecoded, e_affine, line: line)
                print("e before: \(e)")
                e = e + Projective.generator
                print("e after: \(e)")
            }
            print("suiteData.count: \(suiteData.count)")
            XCTAssertEqual(suiteData.count, 96000, line: line)
            print("expected.count: \(expected.count)")
            print("v.count: \(v.count)")
            XCTAssertBytesEqual(v, suiteData, line: line)
        }
    }
}
