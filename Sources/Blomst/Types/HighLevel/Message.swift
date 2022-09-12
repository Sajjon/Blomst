//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-04.
//

import Foundation

public typealias Message = Data
public typealias DomainSeperationTag = Data
public typealias Augmentation = Data

import BLST
public func expandMessageXMD(
    toLength outLength: Int,
    message: Message,
    domainSeperationTag: DomainSeperationTag = .init()
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
