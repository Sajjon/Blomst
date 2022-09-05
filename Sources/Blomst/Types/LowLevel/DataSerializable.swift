//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation

public protocol DataSerializable {
    func toData() -> Data
}

public extension DataSerializable {
    func hex(options: Data.HexEncodingOptions = []) -> String {
        toData().hex(options: options)
    }
}