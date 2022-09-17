//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-13.
//

import Foundation

public protocol AffinePoint {
    associatedtype Component
    var x: Component { get }
    var y: Component { get }
    init(x: Component, y: Component) throws
}

