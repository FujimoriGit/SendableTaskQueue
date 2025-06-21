//
//  SendableOperation.swift
//  SendableTaskQueue
//  
//  Created by Daiki Fujimori on 2025/06/21
//  

import Foundation

protocol SendableOperation: Sendable {
    
    associatedtype Output: Sendable
    /// Timeout interval for this operation (in seconds)
    var timeout: TimeInterval { get }
    /// Execute the operation
    func execute() async throws -> Output
}
