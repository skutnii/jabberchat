//
//  WordpressConnector.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 01.06.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

class WordpressConnector: PXMPPConnector {
    typealias CString = UnsafeMutablePointer<Int8>
    
    private var _connection: OpaquePointer?
    private var _context: OpaquePointer?
    
    private func authenticate() {
        print("JWTAUTH supported")
        
        let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbmV3cy5zdGFnaW5nLnB0dS5hZXJvIiwiaWF0IjoxNTI3ODQ4OTYzLCJuYmYiOjE1Mjc4NDg5NjMsImV4cCI6MTUyODQ1Mzc2MywiZGF0YSI6eyJ1c2VyIjp7ImlkIjoiNTk4In19fQ.QtSzCy_NFp3e9fAjVWija0HRoQFFhn8O0Qv03u61izk"
        let user = "test"
        
        guard let authData = "\(user):\(token)".data(using: .utf8) else {
            return
        }
        
        let authContent = authData.base64EncodedString()
        
        let auth = xmpp_stanza_new(_context)
        xmpp_stanza_set_name(auth, "auth")
        xmpp_stanza_set_ns(auth, "urn:ietf:params:xml:ns:xmpp-sasl")
        xmpp_stanza_set_attribute(auth, "mechanism", "JWTAUTH")
        
        let content = xmpp_stanza_new(_context)
        xmpp_stanza_set_text(content, authContent)
        
        xmpp_stanza_add_child(auth, content)
        xmpp_send(_connection, auth)
        
        xmpp_stanza_release(auth)
        xmpp_stanza_release(content)
    }
    
    private func on(features: OpaquePointer?) {
        guard let mechsWrapper = xmpp_stanza_get_child_by_name(features, "mechanisms") else {
            print("No SASL")
            return
        }
        
        var mechanism = xmpp_stanza_get_children(mechsWrapper)
        while mechanism != nil {
            let name = String(cString: xmpp_stanza_get_text(mechanism))
            if name == "JWTAUTH" {
                authenticate()
                return
            }
            
            mechanism = xmpp_stanza_get_next(mechanism)
        }
        
        print("JWTAUTH not supported by server")
    }
    
    func start(connection: XMPP.Connection, context: XMPP.Context) {
        _connection = connection.opaque
        _context = context.opaque
        
        xmpp_handler_add(connection.opaque, { (_, stanza, objectPtr) -> Int32 in
            CUtils.with(objectAt: objectPtr, { (instance: WordpressConnector) in
                instance.on(features: stanza)
            })
            
            return 0
        }, nil, "features", nil, CUtils.ptr(to: self))
        
        xmpp_conn_open_stream_default(connection.opaque)
    }
}
