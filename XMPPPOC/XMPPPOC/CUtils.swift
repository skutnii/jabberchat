//
//  CUtils.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 01.06.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

class CUtils {
    
    static func with<InstanceType: AnyObject>(objectAt instancePtr: UnsafeMutableRawPointer?, _ block: (InstanceType) -> Void) {
        guard instancePtr != nil else {
            return
        }
        
        let instance = Unmanaged<InstanceType>.fromOpaque(instancePtr!).takeUnretainedValue()
        block(instance)
    }
    
    static func ptr<InstanceType: AnyObject>(to object: InstanceType) -> UnsafeMutableRawPointer? {
        return UnsafeMutableRawPointer(Unmanaged.passUnretained(object).toOpaque())
    }
}

