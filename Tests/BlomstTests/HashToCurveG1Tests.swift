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
        let fp = try Fp1(data: data)
        XCTAssertBytesEqual(data, fp.toData())
    }
    
    func test_hash_to_curve_g1_NU() throws {
        try doTestSuite(name: "BLS12381G1_XMD_SHA-256_SSWU_NU_") { suite, test, testIndex in
            print("🔮 testing vector at: \(testIndex)")
            let message = try test.message()
            let domainSeperationTag = try suite.domainSeparationTag()
           
            let maybeResult: G1Affine? = try suite.operation == .hash ?
                hashToG1(
                    message: message,
                    domainSeperationTag: domainSeperationTag,
                    augmentation: .init()
                ) : (suite.operation == .encode ? encodeToG1(message: message, domainSeperationTag: domainSeperationTag, augmentation: .init()) : nil)
            
            let result = try XCTUnwrap(maybeResult)
            let expected = try test.expected()
            print("result: \(String(describing: result))")
            print("expected: \(String(describing: expected))")
            print("expected.x: \(String(describing: test.P.x))")
            print("expected.y: \(String(describing: test.P.y))")
//            XCTAssertBytesEqual(result, expected)
            XCTAssertEqual(result, expected)
        }
    }

}

private extension HashToCurveG1Tests {
    func doTestSuite(
        name: String,
        testVector: (HashToCurveG1TestSuite, HashToCurveG1TestSuite.Vector, Int) throws -> Void,
        line: UInt = #line
    ) throws {
        try doTestFixture(
            bundleType: Self.self,
            jsonName: name,
            decodeAs: HashToCurveG1TestSuite.self,
            testVectorFunction: testVector
        )
    }
}

/*
 {
   "L": "0x40",
   "Z": "0xb",
   "ciphersuite": "BLS12381G1_XMD:SHA-256_SSWU_NU_",
   "curve": "BLS12-381 G1",
   "dst": "QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_NU_",
   "expand": "XMD",
   "field": {
     "m": "0x1",
     "p": "0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab"
   },
   "hash": "sha256",
   "k": "0x80",
   "map": {
     "name": "SSWU"
   },
   "randomOracle": false,
   "vectors": [
     {
       "P": {
         "x": "0x184bb665c37ff561a89ec2122dd343f20e0f4cbcaec84e3c3052ea81d1834e192c426074b02ed3dca4e7676ce4ce48ba",
         "y": "0x04407b8d35af4dacc809927071fc0405218f1401a6d15af775810e4e460064bcc9468beeba82fdc751be70476c888bf3"
       },
       "Q": {
         "x": "0x11398d3b324810a1b093f8e35aa8571cced95858207e7f49c4fd74656096d61d8a2f9a23cdb18a4dd11cd1d66f41f709",
         "y": "0x19316b6fb2ba7717355d5d66a361899057e1e84a6823039efc7beccefe09d023fb2713b1c415fcf278eb0c39a89b4f72"
       },
       "msg": "",
       "u": [
         "0x156c8a6a2c184569d69a76be144b5cdc5141d2d2ca4fe341f011e25e3969c55ad9e9b9ce2eb833c81a908e5fa4ac5f03"
       ]
     },
 */

protocol Point2DRepresentable {
    associatedtype Magnitude: DataRepresentable
    var x: Magnitude { get }
    var y: Magnitude { get }
    init(x: Magnitude, y: Magnitude) throws
}
extension G1Affine: Point2DRepresentable {
    typealias Magnitude = Fp1
}

typealias HashToCurveG1TestSuite = HashToCurveTestSuite<G1Affine>
struct HashToCurveTestSuite<Element: Point2DRepresentable>: CipherSuite {
    
    let L: String
    let Z: String
    let ciphersuite: String
    let curve: String
    let dst: String
    let expand: String
    let hash: String
    let k: String
    let randomOracle: Bool
    let vectors: [Vector]
    
    
    /*
     {
     "P": {
     "x": "0x184bb665c37ff561a89ec2122dd343f20e0f4cbcaec84e3c3052ea81d1834e192c426074b02ed3dca4e7676ce4ce48ba",
     "y": "0x04407b8d35af4dacc809927071fc0405218f1401a6d15af775810e4e460064bcc9468beeba82fdc751be70476c888bf3"
     },
     "Q": {
     "x": "0x11398d3b324810a1b093f8e35aa8571cced95858207e7f49c4fd74656096d61d8a2f9a23cdb18a4dd11cd1d66f41f709",
     "y": "0x19316b6fb2ba7717355d5d66a361899057e1e84a6823039efc7beccefe09d023fb2713b1c415fcf278eb0c39a89b4f72"
     },
     "msg": "",
     "u": [
     "0x156c8a6a2c184569d69a76be144b5cdc5141d2d2ca4fe341f011e25e3969c55ad9e9b9ce2eb833c81a908e5fa4ac5f03"
     ]
     },
     */
    struct Vector: Decodable {
        struct DecodableElement: Decodable {
            let x: String
            let y: String
            func element() throws -> Element {
                let xData = try Data(hex: x)
                let yData = try Data(hex: y)
                let xPart = try Element.Magnitude(data: xData)
                let yPart = try Element.Magnitude(data: yData)
                let element = try Element(x: xPart, y: yPart)
                print("✨ xData: \(xData.hex), xPart: \(xPart), element: \(element)")
                return element
            }
        }
        let P: DecodableElement
        let Q: DecodableElement
        let msg: String
        let u: [String]
        
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
