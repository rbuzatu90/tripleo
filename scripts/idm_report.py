import sys
import os
from requests.auth import AuthBase
import requests
import json

hostname = 'https://idm1.idm.mylab.test'
url = '/ipa/json'
login_url = '/ipa/session/login_password'
user = 'admin'
password = ''

request = requests.Session()
requests.packages.urllib3.disable_warnings()
request.verify = False

login_header = {'Referer': 'https://idm1.idm.mylab.test/ipa', 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'text/plain'}
data_header = {'Referer': 'https://idm1.idm.mylab.test/ipa', 'Content-Type': 'application/json', 'Accept': 'text/json'}

login_json = {'user': user, 'password': password}
resp = request.post(hostname+login_url, data=login_json)



user_json = {
    "id": 0,
    "method": "user_find/1",
    "params": [
        [],
        {
            "all": 'true',
            "sizelimit": 0,
            "version": "2.231"
        }
    ]
}

x = request.post(hostname+url, data=json.dumps(user_json), headers=data_header)
print x.text
print x

