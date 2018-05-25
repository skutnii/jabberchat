//
//  Stanza.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 23.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

extension XMPP {
    
    class Stanza {
        private var _stanza: OpaquePointer
        private var _context: Context
        
        init(_ rawStanza: OpaquePointer, _ context: Context) {
            _context = context
            _stanza = xmpp_stanza_clone(rawStanza)
        }
        
        init(context: Context) {
            _context = context
            _stanza = xmpp_stanza_new(_context.opaque)
        }
        
        convenience init(_ name: String, context: Context) {
            self.init(context: context)
            self.name = name
        }
        
        convenience init(message body: String, to: String, context: Context) {
            self.init("message", context: context)
            self.to = to
            xmpp_message_set_body(_stanza, body.cString(using: .utf8))
        }
        
        deinit {
            xmpp_stanza_release(_stanza)
        }
        
        var opaque: OpaquePointer {
            return _stanza
        }
        
        var name: String? {
            get {
                guard let name = xmpp_stanza_get_name(_stanza) else {
                    return nil
                }
                
                return String(cString: name)
            }
            
            set(value) {
                xmpp_stanza_set_name(_stanza, value?.cString(using: .utf8))
            }
        }
        
        var text: String? {
            get {
                guard let rawText = xmpp_stanza_get_text(_stanza) else {
                    return nil
                }
                
                let string = String(cString: rawText)
                xmpp_free(_context.opaque, rawText)
                
                return string
            }
            
            set(value) {
                if value != nil {
                    xmpp_stanza_set_text(_stanza, value!.cString(using: .utf8))
                }
            }
        }
        
        var from: String? {
            get {
                guard let raw = xmpp_stanza_get_from(_stanza) else {
                    return nil
                }
                
                return String(cString: raw)
            }
            
            set(value) {
                if value != nil {
                    xmpp_stanza_set_from(_stanza, value?.cString(using: .utf8))
                }
            }
        }
        
        var body: Stanza? {
            guard let raw = xmpp_stanza_get_child_by_name(_stanza, "body".cString(using: .utf8)) else {
                return nil
            }
            
            return Stanza(raw, _context)
        }
        
        var to: String? {
            get {
                guard let raw = xmpp_stanza_get_to(_stanza) else {
                    return nil
                }
                
                return String(cString: raw)
            }
            
            set(value) {
                if value != nil {
                    xmpp_stanza_set_to(_stanza, value!.cString(using: .utf8))
                }
            }
        }
        
        func add(child: Stanza) {
            xmpp_stanza_add_child(_stanza, child._stanza)
        }
        
    }
    
}
