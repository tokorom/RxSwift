//
//  Scheduler.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

// Abstract base class for schedulers.
//
// Oh joy, swift compiler doesn't know how to pass self into callback correctly.
// It will compile, but generates code that you don't want to execute.
public class Scheduler<TimeInterval, Time>: ImmediateScheduler {
    
    public var now : Time {
        get {
            return abstractMethod()
        }
    }
    
    public init() {
        
    }

    public func schedule<StateType>(state: StateType, action: (/*ImmediateScheduler,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        return abstractMethod()
    }
    
    public func scheduleRelative<StateType>(state: StateType, dueTime: TimeInterval, action: (/*Scheduler,*/ StateType) -> RxResult<Disposable>) -> RxResult<Disposable> {
        return abstractMethod()
    }
}


// This is being called every time `Rx` scheduler performs action to
// check the result of the computation.
//
// The default implementation will throw an Exception if the result failed.
//
// It's probably best to make sure all of the errors have been handled before
// the computation finishes, but it's not unreasonable to change the implementation
// for release builds to silently fail (although I would not recommend it).
//
// Changing default behavior is not recommended because possible data corruption
// is "usually" a lot worse than letting the program crash.
//
func ensureScheduledSuccessfully(result: RxResult<Void>) -> RxResult<Void> {
    switch result {
    case .Failure(let error):
        return errorDuringScheduledAction(error);
    default: break
    }
    
    return SuccessResult
}

func errorDuringScheduledAction(error: ErrorType) -> RxResult<Void> {
    let exception = NSException(name: "ScheduledActionError", reason: "Error happened during scheduled action execution", userInfo: ["error": error])
    exception.raise()
    
    return SuccessResult
}
