//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation

public protocol AffineSerializable {
    associatedtype Affine
    func affine() -> Affine
}

