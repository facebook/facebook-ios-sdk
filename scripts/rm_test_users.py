#!/usr/bin/python
#
# Copyright 2010-present Facebook.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import sys
import json
import httplib
from urlparse import urlparse

if len(sys.argv) == 3:
    appId = sys.argv[1];
    appSecret = sys.argv[2];
    print("Deleting test users for app " + appId);
else:
    print("Must specify appId and appSecret.");
    exit(-1);

host = "graph.facebook.com";
fmtGet = "/{0}/accounts/test-users?access_token={0}|{1}";
fmtDel = "/{0}?method=delete&access_token={1}|{2}";

usersPath = fmtGet.format(appId, appSecret);

while usersPath:
    print("Getting users via: " + usersPath);
    conn = httplib.HTTPSConnection(host);
    conn.request("GET", usersPath);
    users = json.loads(conn.getresponse().read());
    print "Got", len(users["data"]), "users.";

    for user in users["data"]:
        print("Deleting user {0}".format(user["id"]));
        delPath = fmtDel.format(user["id"], appId, appSecret);
        conn = httplib.HTTPSConnection(host);
        conn.request("GET", delPath);
        deleteResult = conn.getresponse().read();
        if (deleteResult <> "true"):
            print("delete failed, got " + deleteResult);

    if not "paging" in users:
        break;
    paging = users["paging"];
    if not "next" in users["paging"]:
        break;
    nextUrl = paging["next"];
    prefix = "https://graph.facebook.com";

    if not nextUrl.startswith(prefix):
        print("Paging url does not start with "+prefix);
        break;

    usersPath = nextUrl[len(prefix):];
    print("Continuing next page at: " + usersPath);
