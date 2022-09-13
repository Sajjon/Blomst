//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation

public protocol UncompressedDataRepresentable {
    init(uncompressedData: some ContiguousBytes) throws
}

public protocol CompressedDataRepresentable {
    init(compressedData: some ContiguousBytes) throws
}
