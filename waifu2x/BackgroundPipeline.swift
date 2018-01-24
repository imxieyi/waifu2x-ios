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
    
    /// Track the number of objects in FIFO buffer.
    private let work_sem = DispatchSemaphore(value: 0)
    
    /// Used to wait for operations to complete
    private let wait_sem = DispatchSemaphore(value: 1)
    
    /// FIFO buffer
    private let queue = Queue<T>()
    
    /// Background DispatchQueue to run operations
    private let background: DispatchQueue
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - name: The unique name of the background thread
    ///   - count: How many objects will this pipeline receive?
    ///   - task: The task to run on each object
    ///   - index: Index of the object
    ///   - obj: The object
    init(_ name: String, count: Int, task: @escaping (_ index: Int, _ obj: T) -> Void) {
        self.count = count
        background = DispatchQueue(label: name)
        background.async {
            var index = 0
            while index < self.count {
                if Waifu2x.interrupt {
                    break
                }
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
    
    /// Add an object to FIFO buffer then send a signal.
    ///
    /// - Parameter obj: The object
    public func appendObject(_ obj: T) {
        queue.enqueue(obj)
        work_sem.signal()
    }
    
    /// Wait for work to complete, must be called or it will cause wait&signal imbalance.
    public func wait() {
        wait_sem.wait()
        wait_sem.signal()
    }
    
}
