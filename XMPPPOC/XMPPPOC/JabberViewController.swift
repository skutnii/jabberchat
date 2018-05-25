//
//  ViewController.swift
//  XMPPPOC
//
//  Created by sergii.kutnii on 22.05.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

import UIKit

class JabberViewController: UIViewController {
    
    private var _context = Jabber.Context(logLevel: XMPP_LEVEL_DEBUG)
    private var _connection: Jabber.Connection?
    private var _started = false
    private var _jid: String?
    
    override func loadView() {
        view = chatView
    }
    
    private(set) lazy var chatView: UITextView = {
        let view = UITextView(frame: .zero)
        view.isEditable = false
        
        view.font = UIFont.systemFont(ofSize: 18.0)
        view.textColor = .black
        
        return view
    } ()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    func getCredentials() {
        let alert = UIAlertController(title: "Authorize", message: "Enter your credentials", preferredStyle: .alert)

        var userField: UITextField? = nil
        alert.addTextField { field in
            userField = field
        }
        
        var passwordField: UITextField? = nil
        alert.addTextField { (field) in
            passwordField = field
        }
        
        let submit = UIAlertAction(title: "OK", style: .cancel) {
            [weak self] _ in
            self?.startChat(jid: userField?.text, password: passwordField?.text)
        }
        
        alert.addAction(submit)
        present(alert, animated: true, completion: nil)
    }
        
    func startChat(jid: String?, password: String?) {
        guard !_started else {
            return
        }
        
        _started = true
        
        guard let user = jid else {
            return
        }
        
        _jid = jid
        
        guard let pass = password else {
            return
        }
        
        let acc = Jabber.Account(jid: user, password: pass)
        let connection = Jabber.Connection(account: acc, context: _context)
        _connection = connection
        connection.handlers.append {
            [unowned self] (connection, stanza) in
            
            switch stanza.name {
            case "presence":
                guard let sender = stanza.from else {
                    return
                }
                
                if !sender.contains(user) {
                    connection.sendPresence(to: sender)
                }
            case "message":
                self.display(stanza: stanza)
                self.askReply(to: stanza)
            default:
                return
            }
        }
        
        _context.run(in: RunLoop.main)
    }
    
    func display(stanza: Jabber.Stanza) {
        guard let content = stanza.body?.text else {
            return
        }
        
        var text = chatView.text ?? ""
        text += "***\n"
        text += "From \(stanza.from ?? "unknown") to \(stanza.to ?? "unknown")\n"
        
        text += content + "\n"
        
        DispatchQueue.main.async {
            self.chatView.text = text
        }
    }
    
    func askReply(to stanza: Jabber.Stanza) {
        guard let sender = stanza.from else {
            return
        }
        
        guard stanza.body?.text != nil else {
            return
        }
        
        let alert = UIAlertController(title: "Reply", message: "to \(sender)", preferredStyle: .alert)
        
        var messageBox: UITextField? = nil
        alert.addTextField { field in
            messageBox = field
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancel)
        
        let send = UIAlertAction(title: "Send", style: .default) {
            [weak self] _ in
            self?.send(reply: messageBox?.text, to: sender)
        }
        
        alert.addAction(send)
        
        present(alert, animated: true, completion: nil)
    }
    
    func send(reply: String?, to contact: String) {
        guard let message = reply else {
            return
        }
        
        guard let connection = _connection else {
            return
        }
        
        let reply = Jabber.Stanza(message: message, to: contact, context: _context)
        reply.from = _jid
        
        display(stanza: reply)
        connection.send(reply)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        getCredentials()
    }
}

