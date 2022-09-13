//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation

public protocol CompressedDataSerializable {
    func compressedData() throws -> Data
}

public protocol UncompressedDataSerializable {
    func uncompressedData() throws -> Data
}

#if DEBUG
public extension CompressedDataSerializable {
    func compressedHex(options: Data.HexEncodingOptions = []) -> String {
        try! compressedData().hex(options: options)
    }
    
//    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
//        try compressedData().withUnsafeBytes(body)
//    }
}
#endif // DEBUG
