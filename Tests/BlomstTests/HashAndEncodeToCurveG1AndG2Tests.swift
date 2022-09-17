//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-12.
//

import Foundation
import XCTest
@testable import Blomst
import XCTAssertBytesEqual
import BytesMutation

@MainActor
final class HashToCurveG1Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        DefaultXCTAssertBytesEqualParameters.haltOnPatternNonIdentical = true
    }
    
    func test_fp1_from_data_then_to_data_roundtrip() throws {
        let data = try Data(hex: "184bb665c37ff561a89ec2122dd343f20e0f4cbcaec84e3c3052ea81d1834e192c426074b02ed3dca4e7676ce4ce48ba")
        let fp = try Fp1(uncompressedData: data)
        XCTAssertBytesEqual(
            try! fp.uncompressedData(),
            data
        )
        
    }
    
    func test_hash_to_curve_g1_RO() async throws {
        try await doTestG1(
            name: "BLS12381G1_XMD_SHA-256_SSWU_RO_"
        )
 
    }
    
    func test_hash_to_curve_g1_NU() async throws {
        try await doTestG1(
            name: "BLS12381G1_XMD_SHA-256_SSWU_NU_"
        )
    }
    
    func test_hash_to_curve_g2_NU() async throws {
        try await doTestG2(
            name: "BLS12381G2_XMD_SHA-256_SSWU_NU_"
        )
    }

    func test_hash_to_curve_g2_RO() async throws {
        try await doTestG2(
            name: "BLS12381G2_XMD_SHA-256_SSWU_RO_"
        )
    }
}

private extension HashToCurveG1Tests {
    
    func doTestG1(
        name: String,
        reverseVectorOrder: Bool = false
    ) async throws {
        try await doTest(
            name: name,
            reverseVectorOrder: reverseVectorOrder
        ) { vector in
            let p = vector.P
            let xData = try Data(hex: p.x)
            let yData = try Data(hex: p.y)
            let xPart = try Fp1(bigEndian: xData)
            let yPart = try Fp1(bigEndian: yData)
            let element = try G1Affine(x: xPart, y: yPart)
            return element
        } functionForOperation: { operation in
            switch operation {
            case .encode:
                return _encodeToG1
            case .hash:
                return _hashToG1
            }
        } operationResultToExpected: { projective in
            try projective.affine()
        }
    }
    
    func doTestG2(
        name: String,
        reverseVectorOrder: Bool = false
    ) async throws {
        try await doTest(
            name: name,
            reverseVectorOrder: reverseVectorOrder
        ) { vector in
            let p = vector.P
            
            func fp2(
                _ keyPath: KeyPath<DecodableElement, String>
            ) throws -> Fp2 {
                let hexConcatenated: String = p[keyPath: keyPath]
                // The vector contains REAL and IMG concat together with ","
                let hexParts = hexConcatenated.split(separator: ",").map(String.init)
                let (realHex, imgHex) = (hexParts[0], hexParts[1])
                let realData = try Data(hex: realHex)
                let imgData = try Data(hex: imgHex)
                let real = try Fp1(bigEndian: realData)
                let img = try Fp1(bigEndian: imgData)
                return Fp2(real: real, imaginary: img)
            }
            
            let x = try fp2(\.x)
            let y = try fp2(\.y)
            return try G2Affine(x: x, y: y)
        } functionForOperation: { operation in
            switch operation {
            case .encode:
                return _encodeToG2
            case .hash:
                return _hashToG2
            }
        } operationResultToExpected: { projective in
            projective.affine()
        }
    }
    
    func doTest<Expected: Equatable, OperationResult: Equatable>(
        name: String,
        reverseVectorOrder: Bool = false,
        expectedFromVector: @escaping (HashToCurveTestSuite<Expected>.Vector) throws -> Expected,
        functionForOperation: @escaping (Blomst.Operation) -> (Message, DomainSeperationTag, Augmentation) throws -> OperationResult,
        operationResultToExpected: @escaping (OperationResult) throws -> Expected
    ) async throws {
        
        try await doTestSuite(
            name: name,
            reverseVectorOrder: reverseVectorOrder
        ) { (suite: HashToCurveTestSuite<Expected>, vector: HashToCurveTestSuite<Expected>.Vector, vectorIndex: Int) in
            print("✨ Starting test vector: #\(vectorIndex) in suite: '\(suite.name)'")
            let message = try vector.message()
            let domainSeperationTag = try suite.domainSeparationTag()
            
            let expected = try expectedFromVector(vector)
            let function = functionForOperation(suite.operation)
            let operationResult = try function(message, domainSeperationTag, Augmentation())
            let result = try operationResultToExpected(operationResult)
            XCTAssertEqual(result, expected)
            print("✅ passed test vector: #\(vectorIndex) in suite: '\(suite.name)'")
        }
    }
    
    func doTestSuite<Element: Equatable>(
        name: String,
        reverseVectorOrder: Bool = false,
        testVector: @escaping (HashToCurveTestSuite<Element>, HashToCurveTestSuite<Element>.Vector, Int) throws -> Void,
        line: UInt = #line
    ) async throws {
        try await doTestJSONFixture(
            name: name,
            decodeAs: HashToCurveTestSuite<Element>.self,
            reverseVectorOrder: reverseVectorOrder,
            testVectorFunction: testVector
        )
    }
}

struct HashToCurveTestSuite<Element>: CipherSuite, Decodable {
    
    let ciphersuite: String
    let dst: String
    let randomOracle: Bool
    let vectors: [Vector]

    struct Vector: Decodable {
        let P: DecodableElement
        let msg: String
        
        func message(line: UInt = #line) throws -> Data {
            try XCTUnwrap(msg.data(using: .utf8), line: line)
        }
    }
}

struct DecodableElement: Decodable {
    let x: String
    let y: String
}

extension HashToCurveTestSuite {
    var operation: Blomst.Operation {
        if randomOracle {
            return .hash
        } else {
            return .encode
        }
    }
    
    func domainSeparationTag(line: UInt = #line) throws -> DomainSeperationTag {
        let data = try XCTUnwrap(dst.data(using: .utf8), line: line)
        return .init(data: data)
    }
}
