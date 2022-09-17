//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-13.
//

import Foundation

public protocol MultiplicativeArithmetic {
    static func * (lhs: Self, rhs: Self) -> Self
}


public protocol PointComponentProtocol: MultiplicativeArithmetic, AdditiveArithmetic {
    static var one: Self { get }
}

public protocol ProjectivePoint {
    
    associatedtype Component: PointComponentProtocol
    var x: Component { get }
    var y: Component { get }
    var z: Component { get }
    init(x: Component, y: Component, z: Component) throws
    
    associatedtype Affine: AffinePoint
    func affine() throws -> Affine
    static var generator: Self { get }
    static var identity: Self { get }
    static func +(lhs: Self, rhs: Self) -> Self
}
