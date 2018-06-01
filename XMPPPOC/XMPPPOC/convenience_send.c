//
//  convenience_send.c
//  XMPPPOC
//
//  Created by sergii.kutnii on 01.06.18.
//  Copyright © 2018 Progresstech Inc. All rights reserved.
//

#include "convenience_send.h"

void connection_send_string(xmpp_conn_t *conn, const char* string) {
    xmpp_send_raw_string(conn, "%s", string);
}
