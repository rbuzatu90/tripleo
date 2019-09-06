import sys
import os
import requests
import json
import logging

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%d-%b-%y %H:%M:%S')

hostname = 'https://idm1.mylab.test/ipa'
data_url = '/ipa/json'
login_url = '/ipa/session/login_password'
user = 'admin'
password = ''

request = requests.Session()
requests.packages.urllib3.disable_warnings()
request.verify = False

login_header = {'Referer': hostname, 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'text/plain'}
data_header = {'Referer': hostname, 'Content-Type': 'application/json', 'Accept': 'text/json'}

login_json = {'user': user, 'password': password}

try:
    resp = request.post(hostname+login_url, data=login_json)
except:
    logging.debug("Check DNS and reachability", exc_info=True)

user_search = { 
    "id": 0, 
    "method": "user_find/1", 
    "params": [ 
        [ ],
        { 
            "all": 'true', 
            "sizelimit": 0, 
            "version": "2.231"
        }
    ]
}
user_add = {
    "id": 0,
    "method": "user_add/1",
    "params": [
        [
            "testuser"
        ],
        {
            "givenname": "Test",
            "sn": "User",
            "loginshell": "/bin/bash",
            "gecos": "User from IdM",
            "uidnumber": 300100,
            "gidnumber": 300100,
            "ipauserauthtype": ["radius"],
            "ipatokenradiusconfiglink": "My-Radius-Server",
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

