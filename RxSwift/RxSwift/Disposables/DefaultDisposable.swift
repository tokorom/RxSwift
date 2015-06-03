//
//  DefaultDisposable.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/15/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

public class DefaultDisposable : Disposable {
 
    struct Internal {
        static let instance = DefaultDisposable()
    }
    
    public class func Instance() -> Disposable {
        return Internal.instance
    }
    
    init() {
        
    }
    
    public func dispose() {
    }
}