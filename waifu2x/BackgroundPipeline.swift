//
//  BackgroundPipeline.swift
//  waifu2x-ios
//
//  Created by 谢宜 on 2017/11/5.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation

class BackgroundPipeline <T> {
    
    /// Count of all input objects
    private let count: Int
    
    private var index: Int = 0
    
    private let work_sem = DispatchSemaphore(value: 0)
    
    private var wait_sems: [DispatchSemaphore] = []
    
    private let thread_sem = DispatchSemaphore(value: 1)
    
    private let queue = Queue<T>()
    
    private var background: [DispatchQueue] = []
    
    private func getNextIndex() -> Int {
        thread_sem.wait()
        let i = index
        index += 1
        thread_sem.signal()
        return i
    }
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - name: The unique name of the background thread
    ///   - count: How many objects will this pipeline receive?
    init(_ name: String, count: Int, threads: Int = 1, task: @escaping (Int, T) -> Void) {
        self.count = count
        for i in 0..<threads {
            let queue = DispatchQueue(label: name + "\(i)")
            background.append(queue)
            let wait_sem = DispatchSemaphore(value: 1)
            wait_sems.append(wait_sem)
            queue.async {
                var index = 0
                while index < self.count {
                    autoreleasepool {
                        self.work_sem.wait()
                        index = self.getNextIndex()
                        task(index, self.queue.dequeue()!)
                    }
                }
                wait_sem.signal()
            }
        }
    }
    
    public func appendObject(_ obj: T) {
        queue.enqueue(obj)
        work_sem.signal()
    }
    
    /// Wait for work to complete, must be called
    public func wait() {
        for sem in wait_sems {
            sem.wait()
        }
    }
    
}
