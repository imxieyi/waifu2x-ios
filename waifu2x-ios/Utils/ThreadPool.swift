//
//  ThreadPool.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/15.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation

class ThreadPool <T> {
    
    private let count: Int
    private var queue_semaphores: [DispatchSemaphore] = []
    private var queues: [DispatchQueue] = []
    private let semaphore = DispatchSemaphore(value: 1)
    
    init() {
        count = ProcessInfo.processInfo.activeProcessorCount
        for i in 0..<count {
            queues.append(DispatchQueue(label: "queue\(i)"))
            queue_semaphores.append(DispatchSemaphore(value: 1))
        }
    }
    
    public func run(objs: [T], task: @escaping (Int, T) -> Void) {
        var i = 0
        let n = objs.count
        for s in queue_semaphores {
            s.wait()
        }
        let next = { () -> Int in
            self.semaphore.wait()
            var x = i
            i += 1
            if x >= n {
                x = -1
            }
            self.semaphore.signal()
            return x
        }
        for i in 0..<count {
            let q = queues[i]
            let s = queue_semaphores[i]
            q.async {
                var index = next()
                while index != -1 {
                    task(index, objs[index])
                    index = next()
                }
                s.signal()
            }
        }
        for s in queue_semaphores {
            s.wait()
            s.signal()
        }
    }
    
}
