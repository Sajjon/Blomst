//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-09-05.
//

import Foundation

public protocol DataRepresentable {
    init<D: ContiguousBytes>(data: D) throws
}
