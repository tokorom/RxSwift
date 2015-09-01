//
//  UIStepper+Rx.swift
//  RxCocoa
//
//  Created by Yuta ToKoRo on 9/1/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import UIKit
#if !RX_NO_MODULE
import RxSwift
#endif

extension UIStepper {
    
    public var rx_value: Observable<Double> {
        return rx_value { [unowned self] in self.value }
    }
    
}
