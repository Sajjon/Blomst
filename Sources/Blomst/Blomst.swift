import Foundation
import BLST

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

public func encodeToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G1Affine {
    return try message.withUnsafeBytes { msgBytes in
        try domainSeperationTag.withUnsafeBytes { dstBytes in
            try augmentation.withUnsafeBytes { augBytes in
                var result = blst_p1()
                blst_encode_to_g1(
                    &result,
                    msgBytes.baseAddress,
                    msgBytes.count,
                    dstBytes.baseAddress,
                    dstBytes.count,
                    augBytes.baseAddress,
                    augBytes.count
                )
                let p1 = P1(lowLevel: result)
                return try G1Affine(p1: p1)
            }
        }
    }
}

public func encodeToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G2Affine {
    return try message.withUnsafeBytes { msgBytes in
        try domainSeperationTag.withUnsafeBytes { dstBytes in
            try augmentation.withUnsafeBytes { augBytes in
                var result = blst_p2()
                blst_encode_to_g2(
                    &result,
                    msgBytes.baseAddress,
                    msgBytes.count,
                    dstBytes.baseAddress,
                    dstBytes.count,
                    augBytes.baseAddress,
                    augBytes.count
                )
                let p2 = P2(lowLevel: result)
                return try G2Affine(p2: p2)
            }
        }
    }
}
