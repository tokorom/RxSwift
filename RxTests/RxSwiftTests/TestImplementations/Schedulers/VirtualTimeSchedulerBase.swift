//
//  VirtualTimeSchedulerBase.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/14/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift

protocol ScheduledItem {
    
}

typealias VirtualTimeSchedulerBase = VirtualTimeSchedulerBase_<Void>

class VirtualTimeSchedulerBase_<__> : Scheduler<Int, Int>, Printable {
    typealias ScheduledItem = (() -> RxResult<Void>, AnyObject, Int, time: Int)
    
    var clock : Time
    var enabled : Bool
    
    var now: Time {
        get {
            return self.clock
        }
    }
    
    var description: String {
        get {
            return self.schedulerQueue.description
        }
    }
    
    private var schedulerQueue : [ScheduledItem] = []
    private var ID : Int = 0
    
    init(initialClock: Time) {
        self.clock = initialClock
        self.enabled = false
        super.init()
    }
    
    override func schedule<StateType>(state: StateType, action: (ImmediateScheduler, StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        return self.scheduleRelative(state, dueTime: 0) { s, a in
            return action(s, a)
        }
    }
    
    override func scheduleRelative<StateType>(state: StateType, dueTime: Int, action: (Scheduler<Int, Int>, StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        return schedule(state, time: now + dueTime, action: action)
    }
    
    func schedule<StateType>(state: StateType, time: Int, action: (Scheduler<Int, Int>, StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        let latestID = self.ID
        ID = ID &+ 1
        
        let compositeDisposable = CompositeDisposable()
        
        let actionDescription : ScheduledItem = ({
            return action(self, state).map { disposable in
                compositeDisposable.addDisposable(disposable)
                return ()
            }
        }, RxBox(state), latestID, time)
        
        schedulerQueue.append(actionDescription)
        
        compositeDisposable.addDisposable(AnonymousDisposable {
            var index : Int = 0
            
            for (_, _, id, _) in self.schedulerQueue {
                if id == latestID {
                    self.schedulerQueue.removeAtIndex(index)
                    return
                }
                
                index++
            }
        })
        
        return success(compositeDisposable)
    }
    
    func start() {
        if !enabled {
            enabled = true
            do {
                if let next = getNext() {
                    if next.time > self.now {
                        self.clock = next.time
                    }

                    (next.0)()
                }
                else {
                    enabled = false;
                }
            
            } while enabled
        }
    }
    
    func getNext() -> ScheduledItem? {
        var minDate = Time.max
        var minElement : ScheduledItem? = nil
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