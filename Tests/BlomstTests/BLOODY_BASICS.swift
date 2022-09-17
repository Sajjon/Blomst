//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-13.
//

import XCTest
import Foundation
@testable import Blomst
import XCTAssertBytesEqual
import BLST

@MainActor
final class BloodyBasics: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        DefaultXCTAssertBytesEqualParameters.passOnPatternNonIdentical = true
        DefaultXCTAssertBytesEqualParameters.haltOnPatternNonIdentical = true
    }
    
    func test_fp1_one() throws {
        let sut = try Fp1.one.uncompressedData()
        XCTAssertBytesEqual(
            sut,
            try Data(hex: "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"),
            "Got: \(sut.hex)"
        )
    }
    
    // https://github.com/eduadiez/bls12_381_ietf/blob/cd18ae1828a084af8cc02f9bd10d3aa36e749c62/src/lib.rs#L203-L210
    func test_from_int() throws {
//        let secretKey = SecretKey(scalar: .init(fr: 3333))
        let secretKey = SecretKey.init(scalar: .init(mostSignificantUInt64: 3333))
        try print(secretKey.data().hex)
        try XCTAssertBytesEqual(secretKey.data(), Data(hex: "0000000000000000000000000000000000000000000000000000000000000d05"))
//        try XCTAssertBytesEqual(secretKey.uncompressedData(), Data(hex: "0f756913902e243f40fd18eb12fd66d873d4a9c02f2b1cc000001cbfffffe340"))
        let publicKey = secretKey.publicKey()
        let expectedPublicKeyCompressedData = Data([
            139, 177, 173, 23, 202, 119, 7, 138, 80, 14, 240, 120, 12, 60, 58, 95, 13, 194, 98,
            144, 176, 191, 178, 29, 44, 118, 241, 168, 39, 190, 216, 118, 77, 127, 50, 51, 45, 194,
            219, 48, 132, 177, 250, 234, 41, 19, 78, 167,
        ])
        XCTAssertEqual(expectedPublicKeyCompressedData.hex(), "8bb1ad17ca77078a500ef0780c3c3a5f0dc26290b0bfb21d2c76f1a827bed8764d7f32332dc2db3084b1faea29134ea7")
       
        XCTAssertEqual(try publicKey.compressedData().hex(), expectedPublicKeyCompressedData.hex())
    }
    
    /// https://github.com/eduadiez/bls12_381_ietf/blob/cd18ae1828a084af8cc02f9bd10d3aa36e749c62/src/lib.rs#L180-L195
    func test_secretKey_from_ikm() throws {
        let secretKey = try SecretKey(inputKeyMaterial: "edu".data(using: .utf8)!)
        
        XCTAssertEqual(secretKey, SecretKey(scalar: .init(uint64s: [
            0x46229f89c6de24b9,
            0x918acabb2d1c50e7,
            0xedd0ee81a783e073,
            0x704540e43a495e37,
        ])))

        try XCTAssertBytesEqual(
            secretKey.data(),
            Data(hex: "46229f89c6de24b9918acabb2d1c50e7edd0ee81a783e073704540e43a495e37")
        )
        
        let publicKey = secretKey.publicKey()
        let expectedPublicKeyCompressedData = Data([
            138, 58, 168, 150, 94, 218, 53, 78, 97, 36, 99, 248, 47, 204, 52, 231, 51, 134, 143,
            162, 76, 76, 81, 121, 192, 32, 125, 53, 115, 34, 198, 103, 197, 155, 141, 121, 160, 99,
            200, 222, 213, 1, 150, 80, 152, 29, 195, 29,
        ])
        XCTAssertEqual(expectedPublicKeyCompressedData.hex(), "8a3aa8965eda354e612463f82fcc34e733868fa24c4c5179c0207d357322c667c59b8d79a063c8ded5019650981dc31d")
        XCTAssertEqual(try publicKey.compressedData().hex(), expectedPublicKeyCompressedData.hex())
   
    }
    

}
