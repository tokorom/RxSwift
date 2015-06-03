//
//  VirtualTimeSchedulerBase.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/14/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift

typealias VirtualTimeSchedulerBase = VirtualTimeSchedulerBase_<Void>

protocol ScheduledItemProtocol : Cancelable {
    var time: Int {
        get
    }
    
    func invoke(scheduler: Scheduler<Int, Int>) -> RxResult<Disposable>
}

class ScheduledItem<T> : ScheduledItemProtocol {
    typealias Action = (/*Scheduler<Int, Int>,*/ T) -> RxResult<Disposable>
    
    let action: Action
    let state: T
    let time: Int
    
    var disposed = false
    
    init(action: Action, state: T, time: Int) {
        self.action = action
        self.state = state
        self.time = time
    }
    
    func invoke(scheduler: Scheduler<Int, Int>) -> RxResult<Disposable> {
        return action(/*scheduler,*/ state)
    }
    
    func dispose() {
        self.disposed = true
    }
}


class VirtualTimeSchedulerBase_<__> : Scheduler<Int, Int>, Printable {
    
    var clock : Time
    var enabled : Bool
    
    override var now: Time {
        get {
            return self.clock
        }
    }
    
    var description: String {
        get {
            return self.schedulerQueue.description
        }
    }
    
    private var schedulerQueue : [ScheduledItemProtocol] = []
    
    init(initialClock: Time) {
        self.clock = initialClock
        self.enabled = false
        super.init()
    }
    
    override func schedule<StateType>(state: StateType, action: (/*ImmediateScheduler,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        return self.scheduleRelative(state, dueTime: 0) { /*s,*/ a in
            return action(/*s,*/ a)
        }
    }
    
    override func scheduleRelative<StateType>(state: StateType, dueTime: Int, action: (/*Scheduler<Int, Int>,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        return schedule(state, time: now + dueTime, action: action)
    }
    
    func schedule<StateType>(state: StateType, time: Int, action: (/*Scheduler<Int, Int>,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        let compositeDisposable = CompositeDisposable()
        
        println(time)
        let item =  ScheduledItem(action: action, state: state, time: time)
        
        schedulerQueue.append(item)
        
        compositeDisposable.addDisposable(item)
        
        return success(compositeDisposable)
    }
    
    func start() {
        if !enabled {
            enabled = true
            do {
                if let next = getNext() {
                    if next.disposed {
                        continue
                    }
                    
                    if next.time > self.now {
                        self.clock = next.time
                    }

                    next.invoke(self)
                }
                else {
                    enabled = false;
                }
            
            } while enabled
        }
    }
    
    func getNext() -> ScheduledItemProtocol? {
        var minDate = Time.max
        var minElement : ScheduledItemProtocol? = nil
        var minIndex = -1
        var index = 0
        
        for item in self.schedulerQueue {
            if item.time < minDate {
                minDate = item.time
                minElement = item
                minIndex = index
            }
            
            index++
        }
        
        if minElement != nil {
            self.schedulerQueue.removeAtIndex(minIndex)
        }
        
        return minElement
    }
}