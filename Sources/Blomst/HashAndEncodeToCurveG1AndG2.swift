import Foundation
import BLST

public func hashToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G1Affine {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p1(),
        resultFromLowLevel: G1Affine.init(lowLevel:),
        blstFN: blst_hash_to_g1
    )
}

public func hashToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G2Affine {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p2(),
        resultFromLowLevel: G2Affine.init(lowLevel:),
        blstFN: blst_hash_to_g2
    )
}

internal func _callBlstFN<Result, LowLevel>(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data,
    newLowLevel: @autoclosure () -> LowLevel,
    resultFromLowLevel: (LowLevel) throws -> Result,
    blstFN: (UnsafeMutablePointer<LowLevel>?, UnsafePointer<byte>?, Int, UnsafePointer<byte>?, Int, UnsafePointer<byte>?, Int) -> Void
) throws -> Result {
    try message.withUnsafeBytes { msgBytes in
        try domainSeperationTag.withUnsafeBytes { dstBytes in
            try augmentation.withUnsafeBytes { augBytes in
                var lowLevel = newLowLevel()
                blstFN(
                    &lowLevel,
                    msgBytes.bindMemory(to: UInt8.self).baseAddress!,
                    msgBytes.count,
                    dstBytes.bindMemory(to: UInt8.self).baseAddress!,
                    dstBytes.count,
                    augBytes.bindMemory(to: UInt8.self).baseAddress!,
                    augBytes.count
                )
                
                return try resultFromLowLevel(lowLevel)
            }
        }
    }
}


public func encodeToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G1Affine {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p1(),
        resultFromLowLevel: G1Affine.init(lowLevel:),
        blstFN: blst_encode_to_g1
    )
}

public func encodeToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G2Affine {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p2(),
        resultFromLowLevel: G2Affine.init(lowLevel:),
        blstFN: blst_encode_to_g2
    )
}
