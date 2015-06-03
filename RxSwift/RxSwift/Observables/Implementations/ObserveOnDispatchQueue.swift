//
//  ObserveOnDispatchQueue.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 5/31/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

class ObserveOnDispatchQueueSink<O: ObserverType> : ScheduledSerialSchedulerObserver<O> {
    var disposeLock = Lock()
    
    var cancel: Disposable
    
    init(scheduler: DispatchQueueScheduler, observer: O, cancel: Disposable) {
        self.cancel = cancel
        super.init(scheduler: scheduler, observer: observer)
    }
   
    override func onCore(event: Event<Element>) {
        super.onCore(event)
    }
    
    override func dispose() {
        super.dispose()
        
        let toDispose = disposeLock.calculateLocked { () -> Disposable in
            let originalCancel = self.cancel
            self.cancel = DefaultDisposable.Instance()
            return originalCancel
        }
        
        toDispose.dispose()
    }
}

class ObserveOnDispatchQueue<E> : Producer<E> {
    let scheduler: DispatchQueueScheduler
    let source: Observable<E>
    
    init(source: Observable<E>, scheduler: DispatchQueueScheduler) {
        self.scheduler = scheduler
        self.source = source
    }
    
    override func run<O : ObserverType where O.Element == E>(observer: O, cancel: Disposable, setSink: (Disposable) -> Void) -> Disposable {
        let sink = ObserveOnDispatchQueueSink(scheduler: scheduler, observer: observer, cancel: cancel)
        setSink(sink)
        return source.subscribe(sink)
    }
}