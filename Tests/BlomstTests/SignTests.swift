//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-16.
//

import Foundation
import Blomst
import XCTest
import XCTAssertBytesEqual

final class SignTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func test_sign_vectors() throws {
        try doTestSuite(
            name: "SignatureTestVectors"
        ) { suite, vector, vectorIndex in
            guard vectorIndex > 0 else { return }
            let secretKey = try SecretKey(
                decimalString: vector.secretKeyDecimalString()
            )
            let publicKey = try PublicKey(compressedData: vector.publicKeyData())
            XCTAssertEqual(secretKey.publicKey(), publicKey)
            let signature = try secretKey.sign(
                message: vector.message(),
                domainSeperationTag: vector.dst()
            )
            try XCTAssertEqual(signature.affine().compressedData(), vector.signatureData())
        }
    }
}

private extension SignTests {
    
    func doTestSuite(
        name: String,
        reverseVectorOrder: Bool = false,
        testVector: @escaping (SignTestSuite, SignTestSuite.Test, Int) throws -> Void,
        line: UInt = #line
    ) throws {
        try doTestJSONFixture(
            name: name,
            decodeAs: SignTestSuite.self,
            reverseVectorOrder: reverseVectorOrder,
            testVectorFunction: testVector
        )
    }
}


struct SignTestSuite: TestSuite, Decodable {
    
    public var name: String { "SignTests" }
    public let cases: [Test]
    public var tests: [Test] { cases }

    /*
     {
       "Msg": "",
       "Ciphersuite": "",
       "G1Compressed": "iMfjiO5Y8duaJNcJiwHRNjQpi+vy0VklSXW9RQyw0of8xiLrce3ei0aahRNVG68f",
       "G2Compressed": "tpMntJx8f85XL+S+CDcW+K1dHJhsRBIOgcnGwDb9RkhF/iTtOM/Ok9D0ZHcZ8bteAXh8hH3vRZLMVGVsAzKPLO9i2oUrbNYcy6FEfpTGqXJSeEh/KPPHGfJOKY6eCTqj",
       "BLSPrivKey": "",
       "BLSPubKey": null,
       "BLSSigG2": null
     },
     {
       "Msg": "",
       "Ciphersuite": "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_",
       "G1Compressed": "hMW6jNJQe93jbkaX0CfwuJUHmHHFh+7DY819un+7BfxKvHjAFQ9Glqr4jhBDqXPD",
       "G2Compressed": "qKqzA+M+0U9KkEAEqSvSb/yWnB0efUt/DAQVCnPhhFqRHlGistNp1c7wZWDFrJ9XFcAVZpk9RGmAXfPh8ptTZIGoMr8nUbaQj67Wd20GLVhVIYiSMpmdcrZ51uOLtc//",
       "BLSPrivKey": "27539689655622540958679105641905086851274830069992722298279813327323206776590",
       "BLSPubKey": "sr4R3I5U7nTbwHVp/XT+A7X1Ktcc1JqFebbGOHiR9aIK2YDsJ0dhjBua01hGpoo+",
       "BLSSigG2": "tTz9+LSIoobfHtIEMuK7xOY2EAN1ff2jpP1s2Y3pXlUT98RI1wsmgeFFR6bO1H58EOKEMuiryzTeHcKPOTKP0qE9sSpMajC9F7DkKIGkKQA+TCRYO6DymkD9g2zwXhpA"
     },
     */
    struct Test: Decodable {
        let Msg: String
        let Ciphersuite: String
        let G1Compressed: String
        let G2Compressed: String
        let BLSPrivKey: String
        let BLSPubKey: String
        let BLSSigG2: String
        
        func message(line: UInt = #line) throws -> Data {
            try XCTUnwrap(Msg.data(using: .utf8), line: line)
        }
        func dst(line: UInt = #line) throws -> DomainSeperationTag {
            let data = try XCTUnwrap(Ciphersuite.data(using: .utf8), line: line)
            return DomainSeperationTag(data: data)
        }
        func secretKeyDecimalString() throws -> String {
            BLSPrivKey
        }
        
        func signatureData(line: UInt = #line) throws -> Data {
            let base64Encoded = try XCTUnwrap(BLSSigG2, line: line)
            return try XCTUnwrap(Data(base64Encoded: base64Encoded), line: line)
        }
        
        func publicKeyData(line: UInt = #line) throws -> Data {
            let base64Encoded = try XCTUnwrap(BLSPubKey, line: line)
            return try XCTUnwrap(Data(base64Encoded: base64Encoded), line: line)
        }
    }
}

