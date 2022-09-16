//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation

/// Do NOT also conform to `UncompressedDataRepresentable` or `CompressedDataRepresentable`, they should be mutally exclusive.
public protocol DataRepresentable {
    init(data: some ContiguousBytes) throws
}


/// Do NOT also conform to `DataRepresentable`, that and this protocol should be mutally exclusive.
public protocol UncompressedDataRepresentable {
    init(uncompressedData: some ContiguousBytes) throws
}

/// Do NOT also conform to `DataRepresentable`, that and this protocol should be mutally exclusive
public protocol CompressedDataRepresentable {
    init(compressedData: some ContiguousBytes) throws
}
