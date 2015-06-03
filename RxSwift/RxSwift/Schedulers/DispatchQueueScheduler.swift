//
//  DispatchQueueScheduler.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

var DispatchQueueSerialMarker = 0


public typealias DispatchQueueScheduler = DispatchQueueScheduler_<Void>

// This is a scheduler that wraps dispatch queue. 
// It can wrap both serial and concurrent dispatch queues.
//
// In case serial dispatch queue needs to get wrapped, there is an optimized version
// of scheduler for serial dispatch queue called `SerialDispatchQueueScheduler`.
public class DispatchQueueScheduler_<__> : Scheduler<NSTimeInterval, NSDate> {
    private let serialQueue : dispatch_queue_t
    
    public override var now : NSDate {
        get {
            return NSDate()
        }
    }
    
    init(serialQueue: dispatch_queue_t) {
        self.serialQueue = serialQueue
    }
    
    // Creates new serial queue named `name` for internal scheduler usage
    public convenience init(internalSerialQueueName: String, serialQueueConfiguration: (dispatch_queue_t) -> Void) {
        let queue = dispatch_queue_create(internalSerialQueueName, DISPATCH_QUEUE_SERIAL)
        serialQueueConfiguration(queue)
        self.init(serialQueue: queue)
    }
    
    public convenience init(queue: dispatch_queue_t, internalSerialQueueName: String) {
        let serialQueue = dispatch_queue_create(internalSerialQueueName, DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(serialQueue, queue)
        self.init(serialQueue: serialQueue)
    }
    
    // DISPATCH_QUEUE_PRIORITY_DEFAULT
    // DISPATCH_QUEUE_PRIORITY_HIGH
    // DISPATCH_QUEUE_PRIORITY_LOW
    public convenience init(priority: Int) {
        self.init(priority: priority, internalSerialQueueName: "rx.global_dispatch_queue.serial.\(priority)")
    }

    public convenience init(priority: Int, internalSerialQueueName: String) {
        self.init(queue: dispatch_get_global_queue(priority, UInt(0)), internalSerialQueueName: internalSerialQueueName)
    }
    
    class func convertTimeIntervalToDispatchTime(timeInterval: NSTimeInterval) -> dispatch_time_t {
        return dispatch_time(DISPATCH_TIME_NOW, Int64(timeInterval * Double(NSEC_PER_SEC) / 1000))
    }
    
    public override func schedule<StateType>(state: StateType, action: (/*ImmediateScheduler,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        let cancel = SingleAssignmentDisposable()
        
        dispatch_async(self.serialQueue) {
            if cancel.disposed {
                return
            }
            
            _ = ensureScheduledSuccessfully(action(/*self,*/ state).map { disposable in
                cancel.setDisposable(disposable)
            })
        }
        
        return success(cancel)
    }
    
    public override func scheduleRelative<StateType>(state: StateType, dueTime: NSTimeInterval, action: (/*Scheduler<NSTimeInterval, NSDate>,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.serialQueue)
        
        let dispatchInterval = MainScheduler.convertTimeIntervalToDispatchTime(dueTime)
        
        let compositeDisposable = CompositeDisposable()
        
        dispatch_source_set_timer(timer, dispatchInterval, DISPATCH_TIME_FOREVER, 0)
        dispatch_source_set_event_handler(timer, {
            if compositeDisposable.disposed {
                return
            }
            ensureScheduledSuccessfully(action(/*self,*/ state).map { disposable in
                compositeDisposable.addDisposable(disposable)
            })
        })
        dispatch_resume(timer)
        
        compositeDisposable.addDisposable(AnonymousDisposable {
            dispatch_source_cancel(timer)
        })
        
        return success(compositeDisposable)
    }
}