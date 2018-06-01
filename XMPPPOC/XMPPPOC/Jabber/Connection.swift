//
//  Connection.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 22.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

extension Jabber {
    
    class Connection {
        
        let account: Account
        private let _context: Context
        fileprivate var _connection: OpaquePointer
        
        private var _connected: Bool = false
        
        init(account: Account, context: Context) {
            self.account = account
            _context = context
            
            _connection = xmpp_conn_new(_context.opaque)
            xmpp_conn_set_jid(_connection, account.jid.cString(using: .utf8))
            xmpp_conn_set_pass(_connection, account.password.cString(using: .utf8))
            
            xmpp_connect_raw(_connection,
                                nil,
                                0,
                                { (conn, status, error, streamError, object) in
                                    Connection.onConnect(conn, status, error, streamError, object)
                                },
                                thisPtr)
        }
        
        deinit {
            close()
            xmpp_conn_release(_connection)
        }
        
        private static func instanceDispatch(_ instancePtr: UnsafeMutableRawPointer?, _ action: (Connection) -> ()) {
            guard instancePtr != nil else {
                return
            }
            
            let instance = Unmanaged<Connection>.fromOpaque(instancePtr!).takeUnretainedValue()
            action(instance)
        }
        
        private static func onConnect(_ conn: OpaquePointer?,
                                      _ status: xmpp_conn_event_t,
                                      _ error: Int32,
                                      _ streamError: UnsafeMutablePointer<xmpp_stream_error_t>?,
                                      _ object: UnsafeMutableRawPointer?) {
            instanceDispatch(object) { target in
                target.onConnectionEvent(status, error, streamError)
            }
        }
        
        private static func handler(_ conn: OpaquePointer?, _ rawStanza: OpaquePointer?, _ object: UnsafeMutableRawPointer?) {
            guard let realStanza = rawStanza else {
                return
            }
            
            instanceDispatch(object) { connection in
                let stanza = Stanza(realStanza, connection._context)
                
                for handle in connection.handlers {
                    handle(connection, stanza)
                }
            }
        }
        
        private func onConnectSuccess() {
            let presence = xmpp_presence_new(_context.opaque)
            xmpp_send(_connection, presence)
            xmpp_stanza_release(presence)
            
            _connected = true
            xmpp_handler_add(_connection,
                             { (conn, stanza, object) -> Int32 in
                                Connection.handler(conn, stanza, object)
                                return 1
                             },
                             nil,
                             nil,
                             nil,
                             thisPtr)
        }
        
        private func onConnectFailure() {
        }
                
        private func onConnectionEvent(_ status: xmpp_conn_event_t, _ error: Int32, _ streamError: UnsafeMutablePointer<xmpp_stream_error_t>?) {
            if status == XMPP_CONN_CONNECT {
                onConnectSuccess()
            } else {
                onConnectFailure()
            }
        }
        
        /// A pointer to self
        private var thisPtr: UnsafeMutableRawPointer {
            return UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        }
        
        typealias Handler = (Connection, Stanza) -> Void
        var handlers = [Handler]()
        
        func send(_ stanza: Stanza) {
            xmpp_send(_connection, stanza.opaque)
        }
        
        func sendPresence(to jid: String) {
            let presence = xmpp_presence_new(_context.opaque)
            xmpp_stanza_set_to(presence, jid.cString(using: .utf8))
            xmpp_send(_connection, presence)
            xmpp_stanza_release(presence)
        }
        
        func close() {
            guard _connected else {
                return
            }
            
            xmpp_disconnect(_connection)
            _connected = false
        }
    }
    
}
