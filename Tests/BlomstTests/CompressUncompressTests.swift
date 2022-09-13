//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-13.
//

import Foundation
import XCTest
import Blomst

final class CompressUncompressTests: XCTestCase {
    func test_g1_compressed() throws {
        try doTestSuite(
            name: "g1_compressed_valid_test_vectors"
        ) { suiteData in
            XCTAssertGreaterThan(suiteData.count, 0)
        }
    }
}

private extension CompressUncompressTests {
    func doTestSuite(
        name: String,
        testSuite: (Data) throws -> Void,
        line: UInt = #line
    ) throws {
        try doTestDATFixture(
            name: name,
            testSuite: testSuite,
            line: line
        )
    }
}
