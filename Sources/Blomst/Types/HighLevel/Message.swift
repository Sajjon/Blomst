//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation

public typealias Message = Data

public struct DomainSeperationTag: Equatable, ContiguousBytes, ExpressibleByStringLiteral {
    public let data: Data
    public static let G2: Self = "BLS_SIG_BLS12381G2-SHA256-SSWU-RO-_NUL_"
    public init(_ string: String) {
        self.init(data: string.data(using: .utf8)!)
    }
    public init(data: Data) {
        self.data = data
    }
    public static let empty = Self(data: .init())
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try data.withUnsafeBytes(body)
    }
}

public typealias Augmentation = Data

import BLST
public func expandMessageXMD(
    toLength outLength: Int,
    message: Message,
    domainSeperationTag: DomainSeperationTag = .empty
) throws -> Data {
    var out = Data.init(repeating: 0x00, count: outLength)
    out.withUnsafeMutableBytes { outBytes in
        message.withUnsafeBytes { msgBytes in
            domainSeperationTag.withUnsafeBytes { dstBytes in
                blst_expand_message_xmd(
                    outBytes.baseAddress,
                    outBytes.count,
                    msgBytes.baseAddress,
                    msgBytes.count,
                    dstBytes.baseAddress,
                    dstBytes.count
                )
            }
        }
    }
    
    return out
}
