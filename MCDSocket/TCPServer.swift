//
//  TCPServer.swift
//  test2
//
//  Created by mconintet on 5/25/16.
//  Copyright © 2016 mconintet. All rights reserved.
//

import Foundation

public class TCPConnection: Socket {
    static var _id = 0
    static var idGen: Int {
        get {
            _id += 1
            return _id
        }
    }

    public let id: Int
    public unowned let server: TCPServer

    public init(sock: CFSocketNativeHandle, server srv: TCPServer) {
        server = srv
        id = TCPConnection.idGen
        super.init(sock: sock)
    }
}

public class TCPServer: Socket, SocketDelegate {

    public let connections = TSMutableDictionary()

    override public init(config cfg: SocketConfig) {
        var cfg = cfg
        cfg.cfsockCallbackType = CFSocketCallBackType.AcceptCallBack.rawValue

        cfg.cfsockCallback = { (sock, cbType, address, data, info) in
            let sock = UnsafePointer<CFSocketNativeHandle>(data).memory
            let srv = UnsafePointer<TCPServer>(info).memory

            let conn = TCPConnection(sock: sock, server: srv)
            conn.delegate = srv
            srv.connections[conn.id] = conn
            srv.handleNewAccpedConnection(conn)

            conn.scheduleStreamInRunLoop()
        }

        super.init(config: cfg)

        var ctx = cfsockContext
        if nil != config.ip4Addr {
            cfsock = CFSocketCreate(kCFAllocatorDefault,
                PF_INET, SOCK_STREAM, IPPROTO_TCP, config.cfsockCallbackType, config.cfsockCallback, &ctx)

            var addr = config.sockaddr4
            let addrPtr = withUnsafePointer(&addr) { UnsafePointer<UInt8>($0) }
            CFSocketSetAddress(cfsock, CFDataCreate(kCFAllocatorDefault, addrPtr, sizeof(sockaddr_in)))
        } else if nil != config.ip6Addr {
            cfsock = CFSocketCreate(kCFAllocatorDefault,
                PF_INET6, SOCK_STREAM, IPPROTO_TCP, config.cfsockCallbackType, config.cfsockCallback, &ctx)

            var addr = config.sockaddr6
            let addrPtr = withUnsafePointer(&addr) { UnsafePointer<UInt8>($0) }
            CFSocketSetAddress(cfsock, CFDataCreate(kCFAllocatorDefault, addrPtr, sizeof(sockaddr_in6)))
        }

        sock = CFSocketGetNative(cfsock)

        if config.sockOptReuseAddr {
            var yes = 1
            setsockopt(CFSocketGetNative(cfsock), SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(sizeofValue(yes)))
        }

        var opt = CFSocketGetSocketFlags(cfsock)
        opt |= kCFSocketCloseOnInvalidate
        CFSocketSetSocketFlags(cfsock, opt)
    }

    public var cfsockContext: CFSocketContext {
        get {
            var ctx = CFSocketContext()
            let ptr = UnsafeMutablePointer<TCPServer>.alloc(1)
            ptr.initialize(self)
            ctx.info = UnsafeMutablePointer<Void>(ptr)
            return ctx
        }
    }

    public func handleNewAccpedConnection(conn: TCPConnection) {
        print(#function)
    }

    public func handleReadStreamOpenCompleted(forSock: Socket) {
        print(#function)
    }

    public func handleReadStreamHasBytesAvailable(forSock: Socket) {
        print(#function)
    }

    public func handleReadStreamEndEncountered(forSock: Socket) {
        print(#function)
    }

    public func handleReadStreamErrorOccurred(forSock: Socket) {
        print(#function)
    }

    public func handleWriteStreamOpenCompleted(forSock: Socket) {
        print(#function)
    }

    public func handleWriteStreamHasSpaceAvailable(forSock: Socket) {
        print(#function)
    }

    public func handleWriteStreamErrorOccurred(forSock: Socket) {
        print(#function)
    }
}
