
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest

//struct WycheproofTest<T: Codable>: Codable {
//    let algorithm: String
//    let numberOfTests: UInt32
//    let testGroups: [T]
//}

protocol TestSuite<Test>: Decodable where Test: Decodable {
    associatedtype Test
    var name: String { get }
    var tests: [Test] { get }
}
//public struct AnyTestSuite<Test: Decodable> {
//    public let name: String
//    public let tests: [Test]
//}
protocol CipherSuite<Vector>: TestSuite where Vector: Decodable, Test == Vector {
    associatedtype Vector
    var ciphersuite: String { get }
    var vectors: [Vector] { get }
}
extension CipherSuite {
    var tests: [Test] { vectors }
    var name: String { ciphersuite }
}

extension XCTestCase {
    func doTestFixture<S: TestSuite>(
        bundleType: AnyObject,
        jsonName: String,
        file: StaticString = #file,
        line: UInt = #line,
//        decode: (JSONDecoder) throws -> some TestSuite<T>,
        decodeAs: S.Type,
        testVectorFunction: (S, S.Test, Int) throws -> Void
    ) throws {

        let testsDirectory: String = URL(fileURLWithPath: "\(#file)").pathComponents.dropLast(3).joined(separator: "/")
        
        let fileURL = try XCTUnwrap(
            URL(fileURLWithPath: "\(testsDirectory)/TestVectors/\(jsonName).json"),
            file: file,
            line: line
        )

        let data: Data
        
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            XCTFail("Expected to find data at: `\(fileURL.absoluteString)`, but none found, error: \(String(describing: error))")
            return
        }

        let decoder = JSONDecoder()
//        let testSuite = try decode(decoder)
        let testSuite = try decoder.decode(S.self, from: data)
        for (testIndex, test) in testSuite.tests.enumerated() {
            try testVectorFunction(testSuite, test, testIndex)
        }
    }
}
