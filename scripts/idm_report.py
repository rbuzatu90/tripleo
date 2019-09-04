import sys
import os
from requests.auth import AuthBase
import requests
import json

hostname = 'https://idm2.idm.mylab.test'
data_url = '/ipa/json'
login_url = '/ipa/session/login_password'
user = 'admin'
password = ''

request = requests.Session()
requests.packages.urllib3.disable_warnings()
request.verify = False

login_header = {'Referer': 'https://idm2.idm.mylab.test/ipa', 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'text/plain'}
data_header = {'Referer': 'https://idm2.idm.mylab.test/ipa', 'Content-Type': 'application/json', 'Accept': 'text/json'}

login_json = {'user': user, 'password': password}
resp = request.post(hostname+login_url, data=login_json)

user_search = { "id": 0, "method": "user_find/1", "params": [ [ ], { "all": 'true', "sizelimit": 0, "version": "2.231" } ] 
user_add = {
    "id": 0,
    "method": "user_add/1",
    "params": [
        [
            "testuser"
        ],
        {
            "givenname": "Test",
            "ipauserauthtype": ["radius"],
            "ipatokenradiusconfiglink": "Radius-Server",
            "sn": "User",
            "version": "2.230"
        }
    ]
}
raw_data = request.post(hostname+data_url, data=json.dumps(user_json), headers=data_header)
data = json.loads(raw_data.text)

for user in data['result']['result']:
    print user
    #if 'krblastsuccessfulauth' in user:
    #    print user
    
    
#print data['result']['result']

