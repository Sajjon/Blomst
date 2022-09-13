import XCTest
@testable import Blomst
import XCTAssertBytesEqual

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
        XCTAssertThrowsError(try G1Projective(p1: P1(data: bytes)))  { anError in
            guard let error = anError as? G1Projective.Error else {
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
            0x46229f89c6de24b9,
            0x918acabb2d1c50e7,
            0xedd0ee81a783e073,
            0x704540e43a495e37,
        ])))
        
        // Inverse every UInt64, reverse order.
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
       
        
        let publicKey = secretKey.publicKey()
        let expectedPublicKeyCompressedData = Data([
            139, 177, 173, 23, 202, 119, 7, 138, 80, 14, 240, 120, 12, 60, 58, 95, 13, 194, 98,
            144, 176, 191, 178, 29, 44, 118, 241, 168, 39, 190, 216, 118, 77, 127, 50, 51, 45, 194,
            219, 48, 132, 177, 250, 234, 41, 19, 78, 167,
        ])
        XCTAssertEqual(expectedPublicKeyCompressedData.hex(), "8bb1ad17ca77078a500ef0780c3c3a5f0dc26290b0bfb21d2c76f1a827bed8764d7f32332dc2db3084b1faea29134ea7")
       
        XCTAssertEqual(publicKey.compressedData().hex(), expectedPublicKeyCompressedData.hex())
    }
    
    func test_fp1_from_uint64s() throws {
        let fromInts = Fp1(uint64s: [
            0xf0827e0ff0ea4e5a,
            0xf67403477c64ca54,
            0x60105fa92270f03e,
            0x8179958d9ffbbe0f,
            0x51f68ccecfdfc76f,
            0x160a52dda57a6489
        ])
        let fromHex = try Fp1(bigEndian: Data(hex: "f0827e0ff0ea4e5af67403477c64ca5460105fa92270f03e8179958d9ffbbe0f51f68ccecfdfc76f160a52dda57a6489"))
        XCTAssertBytesEqual(fromHex.toData(), fromInts.toData(), haltOnPatternNonIdentical: true)
        XCTAssertEqual(fromHex, fromInts)
    }
  
    
    // https://github.com/eduadiez/bls12_381_ietf/blob/cd18ae1828a084af8cc02f9bd10d3aa36e749c62/src/lib.rs#L219-L319
    func skip_test_sign() async throws {
        let message = Data([72, 101, 108, 108, 111, 33])
        XCTAssertEqual(String(data: message, encoding: .utf8)!, "Hello!")
        let domainSeperationTag = Data([
            66, 76, 83, 95, 83, 73, 71, 95, 66, 76, 83, 49, 50, 51, 56, 49, 71, 50, 45, 83, 72, 65,
            50, 53, 54, 45, 83, 83, 87, 85, 45, 82, 79, 45, 95, 78, 85, 76, 95,
        ])
        XCTAssertEqual(String(data: domainSeperationTag, encoding: .utf8)!, "BLS_SIG_BLS12381G2-SHA256-SSWU-RO-_NUL_")
    
        
        let expected = P2Affine(
            x: .init(
                real: .init(uint64s: [
                    0xf0827e0ff0ea4e5a,
                    0xf67403477c64ca54,
                    0x60105fa92270f03e,
                    0x8179958d9ffbbe0f,
                    0x51f68ccecfdfc76f,
                    0x160a52dda57a6489,
                ]),
                imaginary: .init(uint64s: [
                    0x48c5ac798e356233,
                    0xa071167ae6b912b8,
                    0x6a08e106be121b56,
                    0xea9d2081cd7255a6,
                    0xbfb67f385b878dfa,
                    0x760b83bfc9b79d9,
                ])
            ),
            y: .init(
                real: .init(uint64s: [
                    0x3d9f81c519fc11b9,
                    0xe7c922037530014e,
                    0xf772e99043078d53,
                    0x1deebe94e9dac409,
                    0xc36b0d9b73456be8,
                    0x13faaea8309e22b4,
                ]),
                imaginary: .init(uint64s: [
                    0xb6929583cd3550f4,
                    0x560edf8e11692c36,
                    0xd27eea22e71a6e98,
                    0xc7bdee8f51df6fd5,
                    0xb100ef57a9208cf3,
                    0x2aa3e3219450a96,
                ])
            )
        )
        let result = try hashToG2(
            message: message,
            domainSeperationTag: domainSeperationTag
        ).p2Affine
   
        print("expected: \(expected.hex)")
        print("result: \(result.hex)")
        XCTAssertBytesEqual(result, expected, passOnPatternNonIdentical: true, haltOnPatternNonIdentical: true)
        /*
                assert_eq!(hash_to_g2(&message[..], &dst).into_affine(), result);
                
            // edu@dappnode.io
                let message = [
                    101, 100, 117, 64, 100, 97, 112, 112, 110, 111, 100, 101, 46, 105, 111,
                ];
                let result = G2Affine::from_xy_unchecked(
                    Fq2 {
                        c0: Fq::from_repr(FqRepr([
                            0x85565d90ac4b44bb,
                            0xd2a434ca17bb4b98,
                            0x22355c585b43e12d,
                            0x4e9a37112267527d,
                            0xe15ad75d93139482,
                            0x784940eae6f11f9,
                        ]))
                        .unwrap(),
                        c1: Fq::from_repr(FqRepr([
                            0xc42aba5793264316,
                            0xd809a0d362302f9a,
                            0xd7ba024f48577473,
                            0x5b03edf3357d765e,
                            0x2d8aade70cd4e17,
                            0x8edc88475af0832,
                        ]))
                        .unwrap(),
                    },
                    Fq2 {
                        c0: Fq::from_repr(FqRepr([
                            0xe1e12ec63ce51005,
                            0x46de6681c2a53d31,
                            0x6e0ae3e8f8090aee,
                            0xd141442cb38deaa3,
                            0xc35c90eb79ec0fad,
                            0x19c96737dcfb4cf,
                        ]))
                        .unwrap(),
                        c1: Fq::from_repr(FqRepr([
                            0x35a0905c959af032,
                            0x6461705ced47fa2d,
                            0xb9c32d29c4fde6b2,
                            0x4869dbfad2dbbd75,
                            0xa3a780ca1076911f,
                            0x1871351e7d6b1270,
                        ]))
                        .unwrap(),
                    },
                );
                assert_eq!(hash_to_g2(&message[..], &dst).into_affine(), result);
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
