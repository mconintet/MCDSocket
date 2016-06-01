//
//  Socket.swift
//  test2
//
//  Created by mconintet on 5/26/16.
//  Copyright © 2016 mconintet. All rights reserved.
//

import Foundation

public protocol SocketDelegate: NSObjectProtocol {
    func handleReadStreamOpenCompleted(forSock: Socket)

    func handleReadStreamHasBytesAvailable(forSock: Socket)

    func handleReadStreamEndEncountered(forSock: Socket)

    func handleReadStreamErrorOccurred(forSock: Socket)

    func handleWriteStreamOpenCompleted(forSock: Socket)

    func handleWriteStreamHasSpaceAvailable(forSock: Socket)

    func handleWriteStreamErrorOccurred(forSock: Socket)
}

public class Socket: NSObject, NSStreamDelegate {

    public internal(set) var config: SocketConfig

    public weak var delegate: SocketDelegate?

    public internal(set) var sock: CFSocketNativeHandle?
    public internal(set) var cfsock: CFSocket?

    public private(set) var readStream: NSInputStream?
    public private(set) var writeStream: NSOutputStream?

    public private(set) var streamRunloop: NSRunLoop?
    public private(set) var readStreamRunloopMode: String?
    public private(set) var writeStreamRunloopMode: String?

    public var tag = 0

    public let buffer = NSMutableData()

    public init(config cfg: SocketConfig) {
        assert(cfg.isValid)
        config = cfg
    }

    public init(sock s: CFSocketNativeHandle) {
        sock = s
        config = SocketConfig()
        do { try config.form(s) } catch { }
    }

    public private(set) var cfRunloopSource: CFRunLoopSource?
    public private(set) var cfRunloop: CFRunLoop?

    public func prepareReadWriteStream() {
        guard let s = sock else {
            return
        }

        var rs: Unmanaged<CFReadStreamRef>?
        var ws: Unmanaged<CFWriteStreamRef>?
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, s, &rs, &ws)

        readStream = rs!.takeRetainedValue() as NSInputStream
        writeStream = ws!.takeRetainedValue() as NSOutputStream
    }

    public func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        guard let d = delegate else {
            return
        }

        if aStream.isEqual(readStream) {
            switch eventCode {
            case NSStreamEvent.OpenCompleted:
                d.handleReadStreamOpenCompleted(self)
            case NSStreamEvent.HasBytesAvailable:
                d.handleReadStreamHasBytesAvailable(self)
            case NSStreamEvent.EndEncountered:
                d.handleReadStreamEndEncountered(self)
            case NSStreamEvent.ErrorOccurred:
                d.handleReadStreamErrorOccurred(self)
            default:
                break
            }
        } else {
            switch eventCode {
            case NSStreamEvent.OpenCompleted:
                d.handleWriteStreamOpenCompleted(self)
            case NSStreamEvent.HasSpaceAvailable:
                d.handleWriteStreamHasSpaceAvailable(self)
            case NSStreamEvent.ErrorOccurred:
                d.handleWriteStreamErrorOccurred(self)
            default:
                break
            }
        }
    }

    public func scheduleStreamInRunLoop(runloop: NSRunLoop = NSRunLoop.currentRunLoop(),
        readable: Bool = true, readStreamRunloopMode rm: String = NSRunLoopCommonModes,
        writable: Bool = true, writeStreamRunloopMode wm: String = NSRunLoopCommonModes)
    {
        guard true == readable || true == writable else {
            return
        }

        prepareReadWriteStream()

        streamRunloop = runloop

        if readable {
            readStreamRunloopMode = rm
            readStream!.delegate = self
            readStream!.open()
            readStream!.scheduleInRunLoop(runloop, forMode: readStreamRunloopMode!)
        }

        if writable {
            writeStreamRunloopMode = wm
            writeStream!.delegate = self
            writeStream!.open()
            writeStream!.scheduleInRunLoop(runloop, forMode: writeStreamRunloopMode!)
        }
    }

    public func scheduleInRunLoop(runloop: CFRunLoop = CFRunLoopGetCurrent(),
        forMode: String = kCFRunLoopCommonModes as String)
    {
        guard let s = cfsock else {
            return
        }

        cfRunloop = runloop
        cfRunloopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, s, 0)
        CFRunLoopAddSource(cfRunloop, cfRunloopSource, forMode)
    }

    public var hasBytesAvailable: Bool {
        get {
            guard let r = readStream else {
                return false
            }
            return r.hasBytesAvailable
        }
    }

    public var hasSpaceAvailable: Bool {
        get {
            guard let w = writeStream else {
                return false
            }
            return w.hasSpaceAvailable
        }
    }

    public func read(buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard let r = readStream else {
            return -1
        }
        return r.read(buffer, maxLength: len)
    }

    public func write(buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        guard let w = writeStream else {
            return -1
        }
        return w.write(buffer, maxLength: len)
    }

    public func close() {
        if let r = readStream {
            r.close()
            readStream = nil
        }

        if let w = writeStream {
            w.close()
            writeStream = nil
        }

        if let s = cfsock {
            CFSocketInvalidate(s)
            cfsock = nil
        }

        if let s = sock {
            Darwin.close(s)
            sock = nil
        }

        buffer.length = 0
    }
}
