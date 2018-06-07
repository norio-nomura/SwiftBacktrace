//
//  sigaction.swift
//  SwiftBacktrace
//
//  Created by Norio Nomura on 6/6/18.
//

import Foundation

extension sigaction {
    public init(_ action: @escaping @convention(c) (Int32) -> Void) {
    #if _runtime(_ObjC)
        self.init()
        self.__sigaction_u.__sa_handler = action
    #elseif os(Linux)
        self.init()
        self.__sigaction_handler.sa_handler = action
    #else
        self.init()
        #if swift(>=4.1.50)
            #warning("unsupported platform")
        #endif
    #endif
    }
}

public func handle(signal: Int32, action: @escaping @convention(c) (Int32) -> Void) {
    var action = sigaction(action)
    sigaction(signal, &action, nil)
}
