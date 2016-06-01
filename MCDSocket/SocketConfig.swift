//
//  SocketConfig.swift
//  test2
//
//  Created by mconintet on 5/26/16.
//  Copyright © 2016 mconintet. All rights reserved.
//

import Foundation

public enum SocketConfigError: ErrorType {
    case MissingAddr
    case MissingIPVersion
    case MissingProtocol
    case MissingCallback
    case DeformedIP4Addr
    case DeformedIP6Addr
    case UnsupportedSock
}

public struct SocketConfig {
    public var addr4: String? = nil
    public var addr6: String? = nil

    public var port: UInt16 = 0

    public var ip4Addr: in_addr_t? = nil
    public var ip6Addr: in6_addr? = nil

    public var sockOptReuseAddr = true

    public var cfsockCallbackType: CFOptionFlags = CFSocketCallBackType.NoCallBack.rawValue
    public var cfsockCallback: CFSocketCallBack? = nil

    public private(set) var isValid = false

    public init() { }

    public var sockaddr4: sockaddr_in {
        get {
            guard let a4 = ip4Addr else {
                return sockaddr_in()
            }
            var addr = sockaddr_in()
            addr.sin_len = UInt8(sizeof(sockaddr_in))
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = in_port_t(port.bigEndian)
            addr.sin_addr.s_addr = a4
            return addr
        }
    }

    public var sockaddr6: sockaddr_in6 {
        get {
            guard let a6 = ip6Addr else {
                return sockaddr_in6()
            }
            var addr = sockaddr_in6()
            addr.sin6_len = UInt8(sizeof(sockaddr_in6))
            addr.sin6_family = sa_family_t(AF_INET6)
            addr.sin6_port = in_port_t(port.bigEndian)
            addr.sin6_addr = a6
            return addr
        }
    }

    static public func ip4to6(v4: in_addr_t) -> in6_addr {
        let u = in6_addr.__Unnamed_union___u6_addr(__u6_addr32: (0, 0, 0x00FFFF, v4))
        return in6_addr(__u6_addr: u)
    }

    public mutating func validate() throws {
        if nil == addr4 && nil == addr6 && nil == ip4Addr && nil == ip6Addr {
            throw SocketConfigError.MissingAddr
        }

        if CFSocketCallBackType.NoCallBack.rawValue != cfsockCallbackType && nil == cfsockCallback {
            throw SocketConfigError.MissingCallback
        }

        if nil != addr4 && nil == ip4Addr {
            ip4Addr = inet_addr(addr4!)
            if INADDR_NONE == ip4Addr {
                throw SocketConfigError.DeformedIP4Addr
            }
        }

        if nil != addr6 && nil == ip6Addr {
            if 0 == inet_pton(AF_INET6, addr6!, &ip6Addr) {
                throw SocketConfigError.DeformedIP6Addr
            }
        }

        isValid = true
    }

    public mutating func form(sock: CFSocketNativeHandle) throws {
        var addr = sockaddr_storage()
        var addrLen = socklen_t(sizeof(sockaddr_storage))

        try withUnsafeMutablePointers(&addr, &addrLen) { (addrPtr, addrLenPtr) in
            getpeername(sock, UnsafeMutablePointer<sockaddr>(addrPtr), addrLenPtr)

            if UInt8(AF_INET) == addr.ss_family {
                let addr4 = UnsafePointer<sockaddr_in>(addrPtr).memory
                ip4Addr = addr4.sin_addr.s_addr
                port = addr4.sin_port.bigEndian
            } else if UInt8(AF_INET6) == addr.ss_family {
                let addr6 = UnsafePointer<sockaddr_in6>(addrPtr).memory
                ip6Addr = addr6.sin6_addr
                port = addr6.sin6_port.bigEndian
            } else {
                throw SocketConfigError.UnsupportedSock
            }
        }
    }
}
