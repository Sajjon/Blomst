import Foundation
import BLST

public struct HashOf<Element> {
    public let element: Element
}
extension HashOf: Equatable where Element: Equatable {}
extension HashOf: Hashable where Element: Hashable {}
public struct EncodingOf<Element> {
    public let element: Element
}
extension EncodingOf: Equatable where Element: Equatable {}
extension EncodingOf: Hashable where Element: Hashable {}

public func hashToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> HashOf<G1Projective> {
    
    try .init(element: _hashToG1(message: message, domainSeperationTag: domainSeperationTag, augmentation: augmentation))
}
internal func _hashToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G1Projective {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p1(),
        resultFromLowLevel: G1Projective.init(lowLevel:),
        blstFN: blst_hash_to_g1
    )
}

internal func _hashToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G2Projective {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p2(),
        resultFromLowLevel: G2Projective.init(lowLevel:),
        blstFN: blst_hash_to_g2
    )
}

public func hashToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> HashOf<G2Projective> {
    try .init(element: _hashToG2(message: message, domainSeperationTag: domainSeperationTag, augmentation: augmentation))
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


internal func _encodeToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G1Projective {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p1(),
        resultFromLowLevel: G1Projective.init(lowLevel:),
        blstFN: blst_encode_to_g1
    )
}
public func encodeToG1(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> EncodingOf<G1Projective> {
    try .init(element: _encodeToG1(message: message, domainSeperationTag: domainSeperationTag, augmentation: augmentation))
}

public func encodeToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> EncodingOf<G2Projective> {

    try .init(element: _encodeToG2(message: message, domainSeperationTag: domainSeperationTag, augmentation: augmentation))
}
internal func _encodeToG2(
    message: Message,
    domainSeperationTag: DomainSeperationTag,
    augmentation: Data = .init()
) throws -> G2Projective {
    try _callBlstFN(
        message: message,
        domainSeperationTag: domainSeperationTag,
        augmentation: augmentation,
        newLowLevel: blst_p2(),
        resultFromLowLevel: G2Projective.init(lowLevel:),
        blstFN: blst_encode_to_g2
    )
}
