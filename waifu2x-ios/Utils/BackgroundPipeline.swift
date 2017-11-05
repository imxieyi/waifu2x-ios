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
    
    private let wait_sem = DispatchSemaphore(value: 1)
    
    private let queue = Queue<T>()
    
    private let background: DispatchQueue
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - name: The unique name of the background thread
    ///   - count: How many objects will this pipeline receive?
    init(_ name: String, count: Int, task: @escaping (Int, T) -> Void) {
        self.count = count
        background = DispatchQueue(label: name)
        background.async {
            var index = 0
            while index < self.count {
                autoreleasepool {
                    self.work_sem.wait()
                    task(index, self.queue.dequeue()!)
                    index += 1
                }
            }
            self.wait_sem.signal()
        }
        wait_sem.wait()
    }
    
    public func appendObject(_ obj: T) {
        queue.enqueue(obj)
        work_sem.signal()
    }
    
    /// Wait for work to complete, must be called
    public func wait() {
        wait_sem.wait()
        wait_sem.signal()
    }
    
}
