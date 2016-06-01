//
//  TSMutableArray.swift
//  test2
//
//  Created by mconintet on 5/26/16.
//  Copyright © 2016 mconintet. All rights reserved.
//

import Foundation

public class TSMutableArray {
    let raw = NSMutableArray()
    let lock = NSRecursiveLock()

    public func addObject(anObject: AnyObject) {
        lock.lock()
        defer { lock .unlock() }
        raw.addObject(anObject)
    }

    public func insertObject(anObject: AnyObject, atIndex index: Int) {
        lock.lock()
        defer { lock .unlock() }
        raw.insertObject(anObject, atIndex: index)
    }

    public func removeLastObject() {
        lock.lock()
        defer { lock .unlock() }
        raw.removeLastObject()
    }

    public func removeObjectAtIndex(index: Int)
    {
        lock.lock()
        defer { lock .unlock() }
        raw .removeObjectAtIndex(index)
    }

    public func replaceObjectAtIndex(index: Int, withObject anObject: AnyObject) {
        lock.lock()
        defer { lock .unlock() }
        raw.replaceObjectAtIndex(index, withObject: anObject)
    }

    public var count: Int {
        get {
            lock.lock()
            defer { lock .unlock() }
            return raw.count
        }
    }

    public func objectAtIndex(index: Int) -> AnyObject {
        lock.lock()
        defer { lock .unlock() }
        return raw.objectAtIndex(index)
    }

    public subscript (idx: Int) -> AnyObject {
        set {
            lock.lock()
            defer { lock .unlock() }
            raw.replaceObjectAtIndex(idx, withObject: newValue)
        }
        get {
            lock.lock()
            defer { lock .unlock() }
            return raw.objectAtIndex(idx)
        }
    }
}
