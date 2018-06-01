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
        
        let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC8xOTIuMTY4LjEuMjQ6ODA4MCIsImlhdCI6MTUyNzg2NTA5NiwibmJmIjoxNTI3ODY1MDk2LCJleHAiOjE1Mjg0Njk4OTYsImRhdGEiOnsidXNlciI6eyJpZCI6IjU5OCJ9fX0.RzScZHY4nSrBsIVTZFb4wHbM9tYl9r3xhljEPqvZSyg"
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
    
    private func sendResourceQuery() {
        let iq = xmpp_stanza_new(_context)
        xmpp_stanza_set_name(iq, "iq")
        xmpp_stanza_set_id(iq, "a1")
        xmpp_stanza_set_type(iq, "get")
        
        let query = xmpp_stanza_new(_context)
        xmpp_stanza_set_name(query, "query")
        xmpp_stanza_set_ns(query, "jabber:iq:auth")
        xmpp_stanza_add_child(iq, query)
        xmpp_stanza_release(query)
        
        let username = xmpp_stanza_new(_context)
        xmpp_stanza_set_name(username, "username")
        xmpp_stanza_add_child(query, username)
        xmpp_stanza_release(username)
        
        let usernameContent = xmpp_stanza_new(_context)
        xmpp_stanza_set_text(usernameContent, "test")
        xmpp_stanza_add_child(username, usernameContent)
        xmpp_stanza_release(usernameContent)
        #if false
        let resource = xmpp_stanza_new(_context)
        xmpp_stanza_set_name(resource, "resource")
        xmpp_stanza_add_child(query, resource)
        xmpp_stanza_release(resource)
        
        let resourceContent = xmpp_stanza_new(_context)
        xmpp_stanza_set_text(resourceContent, "newsapp")
        xmpp_stanza_add_child(resource, resourceContent)
        xmpp_stanza_release(resourceContent)
        #endif
        xmpp_send(_connection, iq)
        
        xmpp_stanza_release(iq)
    }
    
    func sendPresence() {
        let presence = xmpp_presence_new(_context)
        xmpp_stanza_set_to(presence, "test@localhost")
        xmpp_send(_connection, presence)
        xmpp_stanza_release(presence)
    }
    
    private func on(sasl event: OpaquePointer?) {
        let name = String(cString: xmpp_stanza_get_name(event))
        switch name {
        case "success":
            print("JWTAUTH SUCCESS")
            sendResourceQuery()
        case "failure":
            print("JWTAUTH FAILURE")
        default:
            return
        }
    }
    
    private func onSessionStart() {
        sendPresence()
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

        xmpp_handler_add(connection.opaque, { (_, stanza, objectPtr) -> Int32 in
            CUtils.with(objectAt: objectPtr, { (instance: WordpressConnector) in
                instance.on(sasl: stanza)
            })
            
            return 1
        }, "urn:ietf:params:xml:ns:xmpp-sasl", nil, nil, CUtils.ptr(to: self))
        
        xmpp_handler_add(connection.opaque, { (_, stanza, objectPtr) -> Int32 in
            CUtils.with(objectAt: objectPtr) { (instance: WordpressConnector) in
                instance.onSessionStart()
            }
            
            return 0
        }, nil, "iq", "result", CUtils.ptr(to: self))

        xmpp_conn_open_stream_default(connection.opaque)
    }
}
