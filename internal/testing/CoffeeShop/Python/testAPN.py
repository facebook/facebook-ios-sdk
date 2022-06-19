#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

"""
    Test script for Apple Push Notification services. Send out payload and
    receive response.

    Adopted from http://gobiko.com/blog/token-based-authentication-http2-example-apns/

    Usage:
        python3 testAPN.py --regId deviceToken

    Required Package:
        pyjwt, cryptography, hyper
"""
import argparse
import json
import time

import jwt
from hyper import HTTPConnection

parser = argparse.ArgumentParser(description="Test APN by sending out payload")
parser.add_argument(
    "--regId",
    default="e41d4aeded3c5fac8cc4d50d7798622843c83c1822e31211d3af8ff32761d05e",
    help="Registration id as device token",
)
parser.add_argument(
    "--use_proxy", action="store_true", help="Use proxy to push notification"
)
args = parser.parse_args()
REGISTRATION_ID = args.regId

# Other Setup
ALGORITHM = "ES256"

APNS_KEY_ID = "C9KPA7R99L"
APNS_AUTH_KEY = "./AuthKey_C9KPA7R99L.p8"
TEAM_ID = "K4VL4R4F8K"
BUNDLE_ID = "FB.CoffeeShop"

f = open(APNS_AUTH_KEY)
secret = f.read()

token = jwt.encode(
    {"iss": TEAM_ID, "iat": time.time()},
    secret,
    algorithm=ALGORITHM,
    headers={
        "alg": ALGORITHM,
        "kid": APNS_KEY_ID,
    },
)

path = "/3/device/{0}".format(REGISTRATION_ID)

request_headers = {
    "apns-expiration": "0",
    "apns-priority": "10",
    "apns-topic": BUNDLE_ID,
    "authorization": "bearer {0}".format(token.decode("ascii")),
}

# Open a connection the APNS server
if args.use_proxy:
    conn = HTTPConnection(
        "api.development.push.apple.com:443", proxy_host="fwdproxy:8080"
    )
else:
    conn = HTTPConnection("api.development.push.apple.com:443")

payload_data = {"aps": {"content-available": 1}}
# payload_data = {
#    'aps': { 'alert' : 'All your base are belong to us.',
#            'content-available': 1}
# }
payload = json.dumps(payload_data).encode("utf-8")

# Send our request
conn.request("POST", path, payload, headers=request_headers)
resp = conn.get_response()
print(resp.status)
print(resp.read())
