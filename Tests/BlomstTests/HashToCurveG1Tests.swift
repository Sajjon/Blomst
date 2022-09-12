//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-12.
//

import Foundation
import XCTest
import Blomst
import XCTAssertBytesEqual

final class HashToCurveG1Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        DefaultXCTAssertBytesEqualParameters.haltOnPatternNonIdentical = true
    }
    
    func test_fp1_from_data_then_to_data_roundtrip() throws {
        let data = try Data(hex: "184bb665c37ff561a89ec2122dd343f20e0f4cbcaec84e3c3052ea81d1834e192c426074b02ed3dca4e7676ce4ce48ba")
        let fp = try Fp1(bigEndian: data)
        XCTAssertBytesEqual(
            fp.toData(),
            try! Data(hex: "3e922090635c8937de40a507546e27e613d5429507169353e884c93ee9cef688c4be45837e1fd02607fb9b8d29ed3d42")
        )
        
    }
    
    func test_hash_to_curve_g1_RO() throws {
        try doTest(
            name: "BLS12381G1_XMD_SHA-256_SSWU_RO_"
        )
 
    }
    
    func test_hash_to_curve_g1_NU_which_encodes() throws {
        try doTest(
            name: "BLS12381G1_XMD_SHA-256_SSWU_NU_"
        )
    }

}

private extension HashToCurveG1Tests {
    
    func doTest(
        name: String,
        reverseVectorOrder: Bool = false
    ) throws {
        
        try doTestSuite(
            name: name,
            reverseVectorOrder: reverseVectorOrder
        ) { suite, test, testIndex in
            let message = try test.message()
            let domainSeperationTag = try suite.domainSeparationTag()
            
            let expected = try test.expected()
            
            let result: G1Affine = try suite.operation.call(message, domainSeperationTag, Augmentation())
       
            XCTAssertEqual(result, expected)
        }
    }
    
    func doTestSuite(
        name: String,
        reverseVectorOrder: Bool = false,
        testVector: (HashToCurveG1TestSuite, HashToCurveG1TestSuite.Vector, Int) throws -> Void,
        line: UInt = #line
    ) throws {
        try doTestFixture(
            bundleType: Self.self,
            jsonName: name,
            decodeAs: HashToCurveG1TestSuite.self,
            reverseVectorOrder: reverseVectorOrder,
            testVectorFunction: testVector
        )
    }
}


protocol Point2DRepresentable {
    associatedtype Magnitude: FromBigEndianBytes
    var x: Magnitude { get }
    var y: Magnitude { get }
    init(x: Magnitude, y: Magnitude) throws
}

extension G1Affine: Point2DRepresentable {
    typealias Magnitude = Fp1
}

extension P1Affine: Point2DRepresentable {
    typealias Magnitude = Fp1
}

typealias HashToCurveG1TestSuite = HashToCurveTestSuite<G1Affine>
struct HashToCurveTestSuite<Element: Point2DRepresentable>: CipherSuite {
    
    let ciphersuite: String
    let dst: String
    let randomOracle: Bool
    let vectors: [Vector]

    struct Vector: Decodable {
        struct DecodableElement: Decodable {
            let x: String
            let y: String
            func element() throws -> Element {
                let xData = try Data(hex: x)
                let yData = try Data(hex: y)
                let xPart = try Element.Magnitude(bigEndian: xData)
                let yPart = try Element.Magnitude(bigEndian: yData)
                let element = try Element(x: xPart, y: yPart)
                return element
            }
        }
        let P: DecodableElement
        let msg: String
        
        func message(line: UInt = #line) throws -> Data {
            try XCTUnwrap(msg.data(using: .utf8), line: line)
        }
        
        func expected() throws -> Element {
            try P.element()
        }
    }
    
}

enum Operation: Equatable {
    case hash
    case encode
    
    var call: (
        _ message: Message,
        _ domainSeperationTag: DomainSeperationTag,
        _ augmentation: Data
    ) throws -> G1Affine {
        switch self {
        case .hash:
            return hashToG1
        case .encode:
            return encodeToG1
        }
    }
}

extension HashToCurveTestSuite {
    var operation: Operation {
        if randomOracle {
            return .hash
        } else {
            return .encode
        }
    }
    
    func domainSeparationTag(line: UInt = #line) throws -> Data {
        try XCTUnwrap(dst.data(using: .utf8), line: line)
    }
}
