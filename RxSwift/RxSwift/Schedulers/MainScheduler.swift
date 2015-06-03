//
//  MainScheduler.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

public typealias MainScheduler = MainScheduler_<Void>

struct MainSchedulerSingleton {
    static let sharedInstance = MainScheduler()
}

public class MainScheduler_<__> : DispatchQueueScheduler {
    let currentScheduler = ImmediateSchedulerOnProducerThread()
    
    private init() {
        super.init(serialQueue: dispatch_get_main_queue())
    }
    
    public class var sharedInstance: MainScheduler {
        get {
            return MainSchedulerSingleton.sharedInstance
        }
    }
    
    public class func ensureExecutingOnScheduler() {
        if !NSThread.currentThread().isMainThread {
            rxFatalError("Executing on wrong scheduler")
        }
    }
    
    public override func schedule<StateType>(state: StateType, action: (/*ImmediateScheduler,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        if NSThread.currentThread().isMainThread {
            return currentScheduler.schedule(state, action: action)
        }
        
        return super.schedule(state, action: action)
    }
}
