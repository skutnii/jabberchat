//
//  Jabber.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 22.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

extension XMPP {
    
    class Account {
        let jid: String
        let password: String
        
        init(jid: String, password: String) {
            self.jid = jid
            self.password = password
        }        
   }
}
