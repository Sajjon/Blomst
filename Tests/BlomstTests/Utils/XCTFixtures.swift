
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

protocol TestSuite<Test> {
    associatedtype Test
    var name: String { get }
    var tests: [Test] { get }
}

protocol CipherSuite<Vector>: TestSuite where Test == Vector {
    associatedtype Vector
    associatedtype Test
    var ciphersuite: String { get }
    var vectors: [Vector] { get }
}
extension CipherSuite {
    var tests: [Test] { vectors }
    var name: String { ciphersuite }
}

extension XCTestCase {
    func doTestJSONFixture<S: TestSuite & Decodable>(
        name: String,
        decodeAs: S.Type,
        reverseVectorOrder: Bool = false,
        testVectorFunction: @escaping (S, S.Test, Int) async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws where S.Test: Decodable {
        try await _doTestSuite(
            fileName: name,
            fileExtension: "json",
            suiteFromData: { try JSONDecoder().decode(S.self, from: $0) },
            testSuite: { suite in
                if reverseVectorOrder {
                    for (testIndex, test) in suite.tests.enumerated().reversed() {
                        try await testVectorFunction(suite, test, testIndex)
                    }
                } else {
                    for (testIndex, test) in suite.tests.enumerated() {
                        try await testVectorFunction(suite, test, testIndex)
                    }
                }
            },
            file: file,
            line: line
        )
    }
    
    func doTestDATFixture(
        name: String,
        file: StaticString = #file,
        line: UInt = #line,
        testSuite: @escaping (Data) throws -> Void
    ) async throws {
        try await _doTestSuite(
            fileName: name,
            fileExtension: "dat",
            suiteFromData: { $0 },
            testSuite: testSuite,
            file: file,
            line: line
        )
    }
    
}
    
private extension XCTestCase {
    
    @MainActor
    func _doTestSuite<Suite>(
        fileName: String,
        fileExtension: String,
        suiteFromData: @escaping (Data) throws -> Suite,
        testSuite: @escaping (Suite) async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {

        let testsDirectory: String = URL(fileURLWithPath: "\(#file)").pathComponents.dropLast(3).joined(separator: "/")
        
        let fileURL = try XCTUnwrap(
            URL(fileURLWithPath: "\(testsDirectory)/TestVectors/\(fileName).\(fileExtension)"),
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

        let suite = try suiteFromData(data)
       
        try await testSuite(suite)
        
    }
}
