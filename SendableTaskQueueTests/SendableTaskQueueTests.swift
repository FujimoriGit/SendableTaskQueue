//
//  SendableTaskQueueTests.swift
//  SendableTaskQueueTests
//  
//  Created by Daiki Fujimori on 2025/06/21
//  

import Testing
@testable import SendableTaskQueue
import Foundation

@Suite
struct SendableTaskQueueTests {
    
    /// シリアル実行時に、enqueueした順序どおりに処理が完了することを検証するテスト
    @Test
    func serialExecution() async throws {
        
        let queue = SendableTaskQueue(maxConcurrentTasks: 1)
        var results: [Int] = []
        var tasks: [Task<Int, Error>] = []
        // キューに値を順番に登録
        for i in 1...3 {
            
            tasks.append(await queue.enqueue { i })
        }
        // 各タスクの結果を取得し、登録順序が保たれているか確認
        for task in tasks {
            
            let value = try await task.value
            results.append(value)
        }
        
        #expect(results == [1, 2, 3])
    }

    /// 並列実行時に、全タスクが同時に進行し、結果が揃って返却されることを検証するテスト
    @Test
    func concurrentExecution() async throws {
        
        let queue = SendableTaskQueue(maxConcurrentTasks: 3)
        // 遅延時間を変えてタスクを生成
        var tasks: [Task<Int, Error>] = []
        for i in 1...3 {
            
            tasks.append(await queue.enqueue {
                
                try await Task.sleep(nanoseconds: UInt64((4 - i) * 100_000_000))
                return i
            })
        }
        // 結果を取得して、すべての値が返ってきていることを確認
        var results: [Int] = []
        for task in tasks {
            
            let value = try await task.value
            results.append(value)
        }
        
        #expect(Set(results) == Set([1, 2, 3]))
    }

    /// SendableOperationをenqueueし、execute()の戻り値が正しく返却されることを検証するテスト
    @Test
    func operationEnqueue() async throws {
        
        struct DummyOp: SendableOperation {
            
            let value: String
            var timeout: TimeInterval { 1 }
            func execute() async throws -> String { value }
        }
        
        let queue = SendableTaskQueue(maxConcurrentTasks: 1)
        let task = await queue.enqueue(DummyOp(value: "hello"))
        let result = try await task.value
        
        #expect(result == "hello")
    }
}
