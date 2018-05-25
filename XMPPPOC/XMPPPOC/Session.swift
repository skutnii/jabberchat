//
//  Session.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 25.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import Foundation

extension Chat {
    
    class Session {
        
        private(set) var context: XMPP.Context
        private(set) var connection: XMPP.Connection
        
        init(account: XMPP.Account, runLoop: RunLoop) {
            context = XMPP.Context(logLevel: XMPP_LEVEL_DEBUG)
            connection = XMPP.Connection(account: account, context: context)
            context.run(in: runLoop)
        }
    }
}
