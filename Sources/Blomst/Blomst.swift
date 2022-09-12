import Foundation
import BLST

/*
    Hash To Base for FQ2

    Convert a message to a point in the finite field as defined here:
    https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-05#section-5
*/
//pub fn hash_to_base_fq2(message: &[u8], ctr: u8, dst: &[u8]) -> Fq2 {
//    // Copy of `message` with appended zero byte
//    let msg = [&message[..], &[0x0]].concat();
//    let hk = Hkdf::<Sha256>::new(Some(dst), &msg[..]);
//
//    let mut info_pfx = String::from("H2C").into_bytes();
//    info_pfx.push(ctr);
//
//    let mut e = vec![];
//    //for i in (1, ..., m), where m is the extension degree of FQ2
//    for i in 1..3 {
//        let mut info = info_pfx.clone();
//        info.push(i);
//        let mut okm = [0u8; 64];
//        hk.expand(&info, &mut okm)
//            .expect("64 is a valid length for Sha256 to output");
//        let a = BigUint::from_bytes_be(&okm);
//        let x = Fq::from_str(&a.to_str_radix(10))
//            .expect("Error getting Fq from str when trying to hash_to_base_fq2");
//        e.push(x);
//    }
//    Fq2 { c0: e[0], c1: e[1] }
//}

//func hashToBaseFp2(
//    message: Message
//    counter: UInt8,
//    domainSeperationTag: DomainSeperationTag
//) throws -> Fp2 {
//
//}

/*
    Convert a message to a point on G2 as defined here:
    https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-06#section-6.6.3

    The idea is to first hash into FQ2 and then use SSWU to map the result into G2.

    Contants and inputs follow the ciphersuite ``BLS12381G2_XMD:SHA-256_SSWU_RO_`` defined here:
    https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-06#section-8.7.2
*/

// pub fn hash_to_g2(message: &[u8], dst: &[u8]) -> G2 {
//     let u0 = hash_to_base_fq2(message, 0, dst);
//     let u1 = hash_to_base_fq2(message, 1, dst);
//     let q0 = map_to_curve_g2(u0);
//     let q1 = map_to_curve_g2(u1);
//     let mut r = G2::from(q0);
//     let r_2 = G2::from(q1);
//     r.add_assign(&r_2);
//     clear_cofactor_g2(r)
// }

public func hashToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G2Affine {
    return try message.withUnsafeBytes { msgBytes in
        try domainSeperationTag.withUnsafeBytes { dstBytes in
            try augmentation.withUnsafeBytes { augBytes in
                var out = blst_p2()
                blst_hash_to_g2(
                    &out,
                    msgBytes.baseAddress,
                    msgBytes.count,
                    dstBytes.baseAddress,
                    dstBytes.count,
                    augBytes.baseAddress,
                    augBytes.count
                )
                let p2 = P2(lowLevel: out)
                return try G2Affine(p2: p2)
            }
        }
    }
    
}


public func hashToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G1Affine {
    try message.withUnsafeBytes { msgBytes in
        try domainSeperationTag.withUnsafeBytes { dstBytes in
            try augmentation.withUnsafeBytes { augBytes in
                var out = blst_p1()
                blst_hash_to_g1(
                    &out,
                    msgBytes.baseAddress,
                    msgBytes.count,
                    dstBytes.baseAddress,
                    dstBytes.count,
                    augBytes.baseAddress,
                    augBytes.count
                )
                let p1 = P1(lowLevel: out)
                return try G1Affine(p1: p1)
            }
        }
    }
    
}

public func encodeToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G1Affine {
    try message.withUnsafeBytes { msgBytes in
        try domainSeperationTag.withUnsafeBytes { dstBytes in
            try augmentation.withUnsafeBytes { augBytes in
                var out = blst_p1()
                blst_encode_to_g1(
                    &out,
                    msgBytes.baseAddress,
                    msgBytes.count,
                    dstBytes.baseAddress,
                    dstBytes.count,
                    augBytes.baseAddress,
                    augBytes.count
                )
                let p1 = P1(lowLevel: out)
                return try G1Affine(p1: p1)
            }
        }
    }
}
