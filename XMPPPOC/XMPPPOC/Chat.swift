//
//  Chat.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 25.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

class Chat {
    
    let account: XMPP.Account
    init(account: XMPP.Account) {
        self.account = account
    }

    private(set) var session: Session?
    
    //TODO: turn into Observable
    var online: Bool {
        guard let realSession = session else {
            return false
        }
        
        return (realSession.connection.ok.state == .fulfilled)
    }
    
    func connect(on runLoop: RunLoop) -> Promise<Void> {
        let newSession = Session(account: account, runLoop: runLoop)
        session = newSession
        let connection = newSession.connection
        return connection.ok.then {
            [weak connection] in
            connection?.addHandler("default") {
                [unowned self] (_, stanza) in
                self.didReceive(stanza: stanza)
            }
        }
    }
    
    private(set) var talks = [String: Conversation]()
    
    private func newTalk(with contact: String) -> Conversation {
        let talk = Conversation(contact: contact, chat: self)
        talks[contact] = talk
        return talk
    }
    
    func talk(with contact: String) -> Conversation {
        return talks[contact] ?? newTalk(with: contact)
    }
    
    func didReceive(stanza: XMPP.Stanza) {
        guard let sender = stanza.from else {
            return
        }
        
        if sender == account.jid {
            return
        }
        
        switch stanza.name {
        case "presence":
            if talks[sender] == nil {
                let talk = newTalk(with: sender)
                talk.sendPresence()
            }
        case "message":
            guard let content = stanza.body?.text else {
                return
            }
            
            let message = Message(sender: sender, content: content, timestamp: Date())
            onMessage(message)
        default:
            return
        }
    }
    
}
