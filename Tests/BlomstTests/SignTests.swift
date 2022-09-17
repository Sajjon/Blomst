//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-16.
//

import Foundation
@testable import Blomst
import XCTest
import XCTAssertBytesEqual
import BytesMutation

@MainActor
final class SignTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        DefaultXCTAssertBytesEqualParameters.haltOnPatternNonIdentical = true
        DefaultXCTAssertBytesEqualParameters.passOnPatternNonIdentical = true
    }
    
    func test_g1Affine_Generator() throws {
        
        let sut = G1Affine.generator
        try XCTAssertBytesEqual(
            sut.x.uncompressedData(),
            [UInt64]([
                0x5cb3_8790_fd53_0c16,
                0x7817_fc67_9976_fff5,
                0x154f_95c7_143b_a1c1,
                0xf0ae_6acd_f3d0_e747,
                0xedce_6ecc_21db_f440,
                0x1201_7741_9e0b_fb75,
            ]).reduce(Data(), { $0 + $1.data }).swapEndianessOfUInt64sFromBytes()
        )
        try XCTAssertBytesEqual(
            sut.y.uncompressedData(),
            [UInt64]([
                0xbaac_93d5_0ce7_2271,
                0x8c22_631a_7918_fd8e,
                0xdd59_5f13_5707_25ce,
                0x51ac_5829_5040_5194,
                0x0e1c_8c3f_ad00_59c0,
                0x0bbc_3efc_5008_a26a,
            ]).reduce(Data(), { $0 + $1.data }).swapEndianessOfUInt64sFromBytes()
        )
    }
    
    func test_g1Affine_generator_negated() throws {
        let expected = try Data(hex: "17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb114d1d6855d545a8aa7d76c8cf2e21f267816aef1db507c96655b9d5caac42364e6f38ba0ecb751bad54dcd6b939c2ca")
        let sut = try G1Affine.generator.negated()
        try XCTAssertBytesEqual(sut.uncompressedData(), expected)
    }
    
    func test_sign_vectors() async throws {

        try await doTestSuite(
            name: "SignatureTestVectors"
        ) { suite, vector, vectorIndex in
            guard vectorIndex >= 2 else { return }
            
            let message = try vector.message()
            let dst = try vector.dst()
            let g1 = try G1Projective(compressedData: vector.g1CompressedData())
            let g2 = try G2Projective(compressedData: vector.g2CompressedData())
            try XCTAssertEqual(g1, hashToG1(message: message, domainSeperationTag: dst).element)
            try XCTAssertEqual(g2, hashToG2(message: message, domainSeperationTag: dst).element)
            
            
            let secretKey = try SecretKey(
                decimalString: vector.secretKeyDecimalString()
            )
            let publicKey = try PublicKey(compressedData: vector.publicKeyData())
            XCTAssertEqual(secretKey.publicKey(), publicKey)
            let signature = try secretKey.sign(
                message: message,
                domainSeperationTag: dst
            )
            try XCTAssertEqual(signature.affine().compressedData(), vector.signatureData())
            
            // VERIFY
            let isSignatureValid = try await signature.verify(
                publicKey: publicKey,
                message: message,
                domainSeperationTag: dst
            )
            XCTAssertTrue(isSignatureValid)
            
            var isInvalidSignatureValid = try await signature.verify(
                publicKey: publicKey,
                message: message + Data([0xde]),
                domainSeperationTag: dst
            )
            XCTAssertFalse(isInvalidSignatureValid, "Tampered message should not result in signature validation.")
            
            let someOtherPubKey = try PublicKey(uncompressedData: Data(hex: "8bb1ad17ca77078a500ef0780c3c3a5f0dc26290b0bfb21d2c76f1a827bed8764d7f32332dc2db3084b1faea29134ea7"))
            
            isInvalidSignatureValid = try await signature.verify(
                publicKey: someOtherPubKey,
                message: message,
                domainSeperationTag: dst
            )
            
            XCTAssertFalse(isInvalidSignatureValid, "Other public key should not consider to have signed the signature.")
            
            let forgedSignature = Signature(p2: .identity)
            isInvalidSignatureValid = try await forgedSignature.verify(
                publicKey: publicKey,
                message: message,
                domainSeperationTag: dst
            )
            XCTAssertFalse(isInvalidSignatureValid, "Forged signature should not be considered valid.")
            
            isInvalidSignatureValid = try await signature.verify(
                publicKey: publicKey,
                message: message,
                domainSeperationTag: .init(data: Data(hex: "deadbeef"))
            )
            XCTAssertFalse(isInvalidSignatureValid, "Wrong DSTs should not be considered valid.")
        }
    }
}

private extension SignTests {
    
    func doTestSuite(
        name: String,
        reverseVectorOrder: Bool = false,
        testVector: @escaping (SignTestSuite, SignTestSuite.Test, Int) async throws -> Void,
        line: UInt = #line
    ) async throws {
        try await doTestJSONFixture(
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
        
        func g1CompressedData(line: UInt = #line) throws -> Data {
            let base64Encoded = try XCTUnwrap(G1Compressed, line: line)
            return try XCTUnwrap(Data(base64Encoded: base64Encoded), line: line)
        }
        
        func g2CompressedData(line: UInt = #line) throws -> Data {
            let base64Encoded = try XCTUnwrap(G2Compressed, line: line)
            return try XCTUnwrap(Data(base64Encoded: base64Encoded), line: line)
        }
    }
}

