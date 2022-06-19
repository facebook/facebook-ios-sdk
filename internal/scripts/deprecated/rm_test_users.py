#!/usr/bin/python
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import sys
import json
import httplib
import urllib2
import threading
from urlparse import urlparse

if len(sys.argv) >= 3:
    appId = sys.argv[1];
    appSecret = sys.argv[2];
    print("Deleting test users for app " + appId);
    if len(sys.argv) >= 4:
        maxConnections = int(sys.argv[3]);
    else:
        maxConnections = 10;
else:
    print("Must specify appId and appSecret.");
    exit(-1);

host = "graph.facebook.com";
fmtGet = "/{0}/accounts/test-users?access_token={0}|{1}";
fmtDel = "https://graph.facebook.com/{0}?method=delete&access_token={1}|{2}";

usersPath = fmtGet.format(appId, appSecret);

semaphore = threading.BoundedSemaphore(maxConnections);

class DeleteHandler(urllib2.BaseHandler):
    def https_response(self, req, response):
        deleteResponse = response.read();
        if (deleteResponse <> "true"):
            print("delete failed, got " + deleteResponse);
        semaphore.release();
        return response

while usersPath:
    print("Getting users via: " + usersPath);
    conn = httplib.HTTPSConnection(host);
    conn.request("GET", usersPath);
    users = json.loads(conn.getresponse().read());
    print "Got", len(users["data"]), "users.";

    for user in users["data"]:
        semaphore.acquire();
        print("Deleting user {0}".format(user["id"]));
        delPath = fmtDel.format(user["id"], appId, appSecret);
        opener = urllib2.build_opener(DeleteHandler())
        thread = threading.Thread(target=opener.open, args=(delPath,))
        thread.start()

    if not "paging" in users:
        break;
    paging = users["paging"];
    if not "next" in users["paging"]:
        break;
    nextUrl = paging["next"];
    prefix = "https://" + host;

    if not nextUrl.startswith(prefix):
        print("Paging url does not start with "+prefix);
        break;

    usersPath = nextUrl[len(prefix):];
    print("Continuing next page at: " + usersPath);
