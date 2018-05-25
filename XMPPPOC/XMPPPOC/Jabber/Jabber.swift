//
//  Jabber.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 22.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

class Jabber {
    
    private init() {
        xmpp_initialize()
    }
    
    deinit {
        xmpp_shutdown()
    }
    
    private static weak var _shared: Jabber? = nil
    
    private static func getInstance() -> Jabber {
        return _shared ?? {
            let jabber = Jabber()
            _shared = jabber
            return jabber
        } ()
    }

    class Context {
        
        fileprivate var _context: OpaquePointer
        private var _running = false
        
        //Keep a reference to Jabber to automate shutdown
        private var _jabber: Jabber
        
        init(logLevel: xmpp_log_level_t = XMPP_LEVEL_ERROR) {
            let logger = xmpp_get_default_logger(logLevel)
            _context = xmpp_ctx_new(nil, logger)
            _jabber = Jabber.getInstance()
        }
        
        deinit {
            stop()
            xmpp_ctx_free(_context)
        }
        
        private func tick(in runLoop: RunLoop, timeout: UInt) {
            runLoop.perform {
                [weak self, unowned runLoop] in
                guard let target = self else {
                    return
                }
                
                guard target._running else {
                    return
                }
                
                xmpp_run_once(target._context, timeout)
                target.tick(in: runLoop, timeout: timeout)
            }
        }
        
        func run(in runLoop: RunLoop) {
            _running = true
            tick(in: runLoop, timeout: 10)
        }
        
        func stop() {
            _running = false
        }
        
        var opaque: OpaquePointer {
            return _context
        }
        
    }

}
