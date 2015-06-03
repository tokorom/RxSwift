//
//  Observable+Concurrency.swift
//  Rx
//
//  Created by Krunoslav Zaher on 3/15/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

// `observeSingleOn` assumes that observed sequence will have one element
// and in cases it has more than one element it will throw an exception.
//
// Most common use case for `observeSingleOn` would be to execute some work on background thread
// and return result to main thread.
//
// This is a performance gain considering general case.
public func observeSingleOn<E>
    (scheduler: ImmediateScheduler)
    -> Observable<E> -> Observable<E> {
    return { source in
        return ObserveSingleOn(source: source, scheduler: scheduler)
    }
}

// `observeOn` operator optimized for `DispatchQueueScheduler`.
// `DispatchQueueScheduler` is a serial scheduler, and that provides room for optimizations.
// In case concurrent queue is passed to it, it will effectively convert it to serial dispatch queue.
//
// The usual use case for it is dispatching to main dispatch queue
public func observeOn<E>
    (scheduler: DispatchQueueScheduler)
    -> Observable<E> -> Observable<E> {
    return { source in
        return ObserveOnDispatchQueue(source: source, scheduler: scheduler)
    }
}

// 'observeOn` fallback for general `ImmediateScheduler`s
// It supports concurrent schedulers.
//
// Typical use case would be getting long running work of main thread and onto background thread.
//
// It is still not optimized, but since the typical use case assumes that there will be 
// significant resource usage, this shouldn't add too much overhead.
//
// It will be optimized if necessary in future, but it's better to have this feature, and 
// optimize it later if needed, then not to have it optimized.
public func observeOn<E>
    (scheduler: ImmediateScheduler)
    -> Observable<E> -> Observable<E> {
    return { source in
        return source
            >- map { e in
                returnElement(e) >- observeSingleOn(scheduler)
            }
            >- concat
    }
}