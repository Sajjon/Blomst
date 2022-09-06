import XCTest
@testable import Blomst

final class BlomstTests: XCTestCase {
    
    func test_conversion() throws {
        let p1 = P1()
        let affineP1 = p1.affine()
        let p1FromAffine = P1(affine: affineP1)
        XCTAssertEqual(p1, p1FromAffine)
        XCTAssertEqual(affineP1, p1FromAffine.affine())
        let p1Bytes = p1.toData()
        let p1FromBytes = try P1(data: p1Bytes)
        XCTAssertEqual(p1, p1FromBytes)
    }
    
    func test_secret_key_new_does_not_throw() throws {
        XCTAssertNoThrow(try SecretKey())
    }
    
    func test_deserialize_p1() throws {
        // https://github.com/ConsenSys/teku/blob/4fa8f6a8204a56be67eb9dd68b464bff55fe9cf5/bls/src/test/java/tech/pegasys/teku/bls/impl/mikuli/G1PointTest.java#L121
        let bytesHex = "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a"
        let bytes = try Data(hex: bytesHex)
        XCTAssertNoThrow(try P1(data: bytes))
    }
    
    func test_deserialize_p1_invalid_bytes_throws() throws {
        // https://github.com/ConsenSys/teku/blob/4fa8f6a8204a56be67eb9dd68b464bff55fe9cf5/bls/src/test/java/tech/pegasys/teku/bls/impl/mikuli/G1PointTest.java#L121
        let bytesHex = "0xffffd1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a" // replace leading "a491" with "ffff"
        let bytes = try Data(hex: bytesHex)
        XCTAssertThrowsError(try P1(data: bytes))
    }
    
    // https://github.com/ConsenSys/teku/blob/4fa8f6a8204a56be67eb9dd68b464bff55fe9cf5/bls/src/test/java/tech/pegasys/teku/bls/impl/mikuli/G1PointTest.java#L126-L132
    func test_assert_that_an_error_is_throws_when_deserializing_a_point_on_curve_but_not_in_g1() throws {
        let bytesHex = "0x8123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let bytes = try Data(hex: bytesHex)
        XCTAssertThrowsError(try G1Element(p1: P1(data: bytes)))  { anError in
            guard let error = anError as? G1Element.Error else {
                return XCTFail("Wrong error type")
            }
            XCTAssertEqual(error, .notInGroup)
        }
    }
    
    func test_secret_key_from_zeros_throws_error() throws {
        XCTAssertThrowsError(try SecretKey(data: Data(repeating: 0x00, count: SecretKey.byteCount)))
    }
    func test_secret_key_from_too_few_bytes_throws_error() throws {
        XCTAssertThrowsError(try SecretKey(data: Data(repeating: 0xde, count: SecretKey.byteCount - 1))) { anError in
            guard let error = anError as? SecretKey.Error else {
                return XCTFail("Wrong error type")
            }
            XCTAssertEqual(error, .tooFewBytes(got: 47))
        }
    }
    func test_secret_key_from_too_many_bytes_throws_error() throws {
        XCTAssertThrowsError(try SecretKey(data: Data(repeating: 0xde, count: SecretKey.byteCount + 1))) { anError in
            guard let error = anError as? SecretKey.Error else {
                return XCTFail("Wrong error type")
            }
            XCTAssertEqual(error, .tooManyBytes(got: 49))
        }
    }
    
    
    /// https://github.com/eduadiez/bls12_381_ietf/blob/cd18ae1828a084af8cc02f9bd10d3aa36e749c62/src/lib.rs#L180-L195
    func test_secretKey_from_ikm() throws {
        let secretKey = try SecretKey(inputKeyMaterial: "edu".data(using: .utf8)!)
        
        XCTAssertEqual(secretKey, SecretKey(scalar: .init(uint64s: [
            0x704540e43a495e37,
            0xedd0ee81a783e073,
            0x918acabb2d1c50e7,
            0x46229f89c6de24b9,
        ])))
        
        // Inverse every UInt64
        //
        // let res_sk = [
        //     0x704540e43a495e37,
        //     0xedd0ee81a783e073,
        //     0x918acabb2d1c50e7,
        //     0x46229f89c6de24b9,
        // ];
        XCTAssertEqual(secretKey.hex(), "375e493ae440457073e083a781eed0ede7501c2dbbca8a91b924dec6899f2246")
        
        let publicKey = secretKey.publicKey()
        let expectedPublicKeyCompressedData = Data([
            138, 58, 168, 150, 94, 218, 53, 78, 97, 36, 99, 248, 47, 204, 52, 231, 51, 134, 143,
            162, 76, 76, 81, 121, 192, 32, 125, 53, 115, 34, 198, 103, 197, 155, 141, 121, 160, 99,
            200, 222, 213, 1, 150, 80, 152, 29, 195, 29,
        ])
        XCTAssertEqual(expectedPublicKeyCompressedData.hex(), "8a3aa8965eda354e612463f82fcc34e733868fa24c4c5179c0207d357322c667c59b8d79a063c8ded5019650981dc31d")
        XCTAssertEqual(publicKey.compressedData().hex(), expectedPublicKeyCompressedData.hex())
   
    }
    
    // https://github.com/eduadiez/bls12_381_ietf/blob/cd18ae1828a084af8cc02f9bd10d3aa36e749c62/src/lib.rs#L203-L210
    func test_from_string() throws {
       let secretKey = SecretKey(scalar: .init(mostSignigicantInt: 3333))
        XCTAssertEqual(secretKey.hex(), "050d000000000000000000000000000000000000000000000000000000000000")
       
        
        let publicKey = secretKey.publicKey()
        let expectedPublicKeyCompressedData = Data([
            139, 177, 173, 23, 202, 119, 7, 138, 80, 14, 240, 120, 12, 60, 58, 95, 13, 194, 98,
            144, 176, 191, 178, 29, 44, 118, 241, 168, 39, 190, 216, 118, 77, 127, 50, 51, 45, 194,
            219, 48, 132, 177, 250, 234, 41, 19, 78, 167,
        ])
        XCTAssertEqual(expectedPublicKeyCompressedData.hex(), "8bb1ad17ca77078a500ef0780c3c3a5f0dc26290b0bfb21d2c76f1a827bed8764d7f32332dc2db3084b1faea29134ea7")
       
        XCTAssertEqual(publicKey.compressedData().hex(), expectedPublicKeyCompressedData.hex())
        /*
         let a = Bls12::sk_to_pk(Fr::from_str("3333").unwrap());
                let b = [
                    139, 177, 173, 23, 202, 119, 7, 138, 80, 14, 240, 120, 12, 60, 58, 95, 13, 194, 98,
                    144, 176, 191, 178, 29, 44, 118, 241, 168, 39, 190, 216, 118, 77, 127, 50, 51, 45, 194,
                    219, 48, 132, 177, 250, 234, 41, 19, 78, 167,
                ];
                assert_eq!(a.as_ref(), &b[..]);
         */
    }
    
//    /// https://github.com/supranational/blst/blob/master/bindings/rust/src/lib.rs#L1337-L1353
//    func test_sign_verify() async throws {
//        let skBytes: [UInt8] = [
//            0x93, 0xad, 0x7e, 0x65, 0xde, 0xad, 0x05, 0x2a, 0x08, 0x3a,
//            0x91, 0x0c, 0x8b, 0x72, 0x85, 0x91, 0x46, 0x4c, 0xca, 0x56,
//            0x60, 0x5b, 0xb0, 0x56, 0xed, 0xfe, 0x2b, 0x60, 0xa6, 0x3c,
//            0x48, 0x99,
//        ]
//        XCTAssertEqual(skBytes.count, 48)
//
//        /*
//            let dst = b"BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_";
//            let msg = b"hello foo";
//            let sig = sk.sign(msg, dst, &[]);
//
//            let err = sig.verify(true, msg, dst, &[], &pk, true);
//            assert_eq!(err, BLST_ERROR::BLST_SUCCESS);
//         */
//        let secretKey = try SecretKey(data: skBytes)
//        let publicKey = secretKey.publicKey()
//
//        print("publicKey: \(publicKey.hex())")
//        let message = "hello foo".data(using: .utf8)!
//        let dst = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_".data(using: .utf8)!
//
//        let signature = try secretKey.sign(
//            message: message,
//            domainSeperationTag: dst,
//            augmentation: .init()
//        )
//
//        try await signature.verify(
//            groupCheck: true,
//            message: message,
//            domainSeperationTag: dst,
//            publicKey: publicKey
//        )
//
//        do {
//            try await signature.verify(
//                groupCheck: true,
//                message: "wrong msg".data(using: .utf8)!,
//                domainSeperationTag: dst,
//                publicKey: publicKey
//            )
//
//            XCTFail("An signature not valid for forged faked message was considered valid, this is critically bad.")
//        } catch {
//            // all good
//        }
//    }
}
