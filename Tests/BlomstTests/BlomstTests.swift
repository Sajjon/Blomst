import XCTest
@testable import Blomst
import XCTAssertBytesEqual

@MainActor
final class BlomstTests: XCTestCase {
    
    func test_conversion() throws {
        let p1 = P1.generator
        let affineP1 = p1.affine()
        let p1FromAffine = P1(affine: affineP1)
        XCTAssertEqual(p1, p1FromAffine)
        XCTAssertEqual(affineP1, p1FromAffine.affine())
        let p1Bytes = try p1.uncompressedData()
        let p1FromBytes = try P1(uncompressedData: p1Bytes)
        XCTAssertEqual(p1, p1FromBytes)
    }
    
    func test_secret_key_new_does_not_throw() throws {
        XCTAssertNoThrow(try SecretKey())
    }
    
    func test_deserialize_p1() throws {
        // https://github.com/ConsenSys/teku/blob/4fa8f6a8204a56be67eb9dd68b464bff55fe9cf5/bls/src/test/java/tech/pegasys/teku/bls/impl/mikuli/G1PointTest.java#L121
        let bytesHex = "0xa491d1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a"
        let bytes = try Data(hex: bytesHex)
        XCTAssertNoThrow(try P1(uncompressedData: bytes))
    }
    
    func test_deserialize_p1_invalid_bytes_throws() throws {
        // https://github.com/ConsenSys/teku/blob/4fa8f6a8204a56be67eb9dd68b464bff55fe9cf5/bls/src/test/java/tech/pegasys/teku/bls/impl/mikuli/G1PointTest.java#L121
        let bytesHex = "0xffffd1b0ecd9bb917989f0e74f0dea0422eac4a873e5e2644f368dffb9a6e20fd6e10c1b77654d067c0618f6e5a7f79a" // replace leading "a491" with "ffff"
        let bytes = try Data(hex: bytesHex)
        XCTAssertThrowsError(try P1(uncompressedData: bytes))
    }
    
    // https://github.com/ConsenSys/teku/blob/4fa8f6a8204a56be67eb9dd68b464bff55fe9cf5/bls/src/test/java/tech/pegasys/teku/bls/impl/mikuli/G1PointTest.java#L126-L132
    func test_assert_that_an_error_is_throws_when_deserializing_a_point_on_curve_but_not_in_g1() throws {
        let bytesHex = "0x8123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let bytes = try Data(hex: bytesHex)
        XCTAssertThrowsError(try G1Projective(p1: P1(uncompressedData: bytes)))  { anError in
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
    
  
}
