//
//  Conversation.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 25.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

extension Chat {
    
    struct Message {
        let sender: String
        let content: String
        let timestamp: Date
        
        init(sender: String, content: String, timestamp: Date) {
            self.sender = sender
            self.content = content
            self.timestamp = timestamp
        }
    }
    
    class Conversation {
        let contact: String
        
        private(set) var log: [Message] = []
        
        private weak var _chat: Chat?
        
        init(contact: String, chat: Chat) {
            self.contact = contact
            _chat = chat
        }
        
        fileprivate func push(message: Message) {
            log.append(message)
        }
        
        var session: Session? {
            return _chat?.session
        }
        
        func send(message: Message) -> Bool {
            guard let realSession = session else {
                return false
            }
            
            let stanza = XMPP.Stanza(message: message.content, to: contact, context: realSession.context)
            realSession.connection.send(stanza)
            
            push(message: message)
            
            return true
        }
        
        func sendPresence() {
            guard let context = session?.context else {
                return
            }
            
            guard let presence = XMPP.Stanza(presenceTo: contact, context: context) else {
                return
            }
            
            session?.connection.send(presence)
        }
    }
    
    func onMessage(_ message: Message) {
        let dialog = talk(with: message.sender)
        dialog.push(message: message)
    }
}
