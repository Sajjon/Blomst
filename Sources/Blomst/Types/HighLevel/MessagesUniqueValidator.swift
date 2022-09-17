//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-17.
//

import Foundation
import BLST

public enum MessagesUniqueValidator {
    
    static func validator(messages: [Message]) -> Bool {
        let byteSize = blst_uniq_sizeof(messages.count)
       
        var v = [UInt64](
            repeating: 0,
            count: byteSize / 8
        )
        
        let ctx: UnsafeMutablePointer<blst_uniq> = v.withUnsafeMutableBytes {
            let ctx = $0.baseAddress!.bindMemory(to: blst_uniq.self, capacity: byteSize)
            blst_uniq_init(ctx)
            return ctx
        }
        
        guard messages.allSatisfy({ msg in
            msg.withUnsafeBytes { msgBytes in
                blst_uniq_test(ctx, msgBytes.baseAddress, msgBytes.count)
            }
        }) else {
            return false
        }
        return true
    }
}

