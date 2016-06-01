//
//  TSMutableDictionary.swift
//  test2
//
//  Created by mconintet on 5/26/16.
//  Copyright © 2016 mconintet. All rights reserved.
//

import Foundation

public class TSMutableDictionary {
    let raw = NSMutableDictionary()
    let lock = NSRecursiveLock()

    public var count: Int {
        get {
            lock.lock()
            defer { lock .unlock() }
            return raw.count
        }
    }

    public func objectForKey(aKey: AnyObject) -> AnyObject? {
        lock.lock()
        defer { lock .unlock() }
        return raw.objectForKey(aKey)
    }

    public func removeAllObjects() {
        lock.lock()
        defer { lock .unlock() }
        raw.removeAllObjects()
    }

    public var allKeys: [AnyObject] {
        get {
            lock.lock()
            defer { lock .unlock() }
            return raw.allKeys
        }
    }

    public var allValues: [AnyObject] {
        get {
            lock.lock()
            defer { lock .unlock() }
            return raw.allValues
        }
    }

    public func removeObjectForKey(aKey: AnyObject) {
        lock.lock()
        defer { lock .unlock() }
        raw.removeObjectForKey(aKey)
    }

    public func setObject(anObject: AnyObject, forKey aKey: NSCopying) {
        lock.lock()
        defer { lock .unlock() }
        raw.setObject(anObject, forKey: aKey)
    }

    public subscript (key: NSCopying) -> AnyObject? {
        get {
            lock.lock()
            defer { lock .unlock() }
            return raw.objectForKey(key)
        }
        set {
            lock.lock()
            defer { lock .unlock() }
            raw.setObject(newValue!, forKey: key)
        }
    }
}
