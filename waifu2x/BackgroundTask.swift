//
//  BackgroundTask.swift
//  waifu2x
//
//  Created by 谢宜 on 2017/12/29.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation

/// Waitable background task
class BackgroundTask {
    
    /// Used to wait for operations to complete
    private let wait_sem = DispatchSemaphore(value: 0)
    
    /// Background DispatchQueue to run operations
    private let background: DispatchQueue
    
    /// Constructor
    ///
    /// - Parameters:
    ///   - name: The unique name of the background thread
    ///   - task: The task to run on each object
    init(_ name: String, task: @escaping () -> Void) {
        background = DispatchQueue(label: name)
        background.async {
            task()
            self.wait_sem.signal()
        }
    }
    
    /// Wait for work to complete, must be called or it will cause wait&signal imbalance.
    public func wait() {
        wait_sem.wait()
    }
    
}
