//
//  convenience_send.h
//  XMPPPOC
//
//  Created by sergii.kutnii on 01.06.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

#ifndef convenience_send_h
#define convenience_send_h

#include <stdio.h>
#include <strophe.h>

void connection_send_string(xmpp_conn_t *conn, const char* string);

#endif /* convenience_send_h */
