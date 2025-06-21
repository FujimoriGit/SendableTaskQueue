//
//  SendableTaskQueue.swift
//  SendableTaskQueue
//  
//  Created by Daiki Fujimori on 2025/06/21
//  

/// Swift Concurrencyを活用した、Sendable準拠の並列制御付きタスクキュー
actor SendableTaskQueue: Sendable {
    
    // MARK: - private property
    
    private let maxConcurrentTasks: Int
    private var currentRunning = 0
    private var pendingUnits: [@Sendable () async -> Void] = []

    // MARK: - initialize
    
    init(maxConcurrentTasks: Int = 1) {
        
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    // MARK: - public method
    
    @discardableResult
    func enqueue<T>(_ work: @Sendable @escaping () async throws -> T) -> Task<T, Error> {
        
        let task = Task<T, Error> {
            
            try await withCheckedThrowingContinuation { cont in
                
                let unit: @Sendable () async -> Void = {
                    
                    do {
                        
                        let result = try await work()
                        cont.resume(returning: result)
                    } catch {
                        
                        cont.resume(throwing: error)
                    }
                }
                
                self.schedule(unit)
            }
        }
        return task
    }
    
    @discardableResult
    func enqueue<T: SendableOperation>(_ operation: T) -> Task<T.Output, Error> {
        
        enqueue { try await operation.execute() }
    }
}

// MARK: - private method

private extension SendableTaskQueue {
    
    func schedule(_ unit: @Sendable @escaping () async -> Void) {
        
        if currentRunning < maxConcurrentTasks {
            
            currentRunning += 1
            
            Task {
                
                await unit()
                self.taskCompleted()
            }
        } else {
            
            pendingUnits.append(unit)
        }
    }
    
    func taskCompleted() {
        
        currentRunning -= 1
        if currentRunning < maxConcurrentTasks, !pendingUnits.isEmpty {
            
            let next = pendingUnits.removeFirst()
            currentRunning += 1
            
            Task {
                
                await next()
                taskCompleted()
            }
        }
    }
}
