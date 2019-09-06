#!/usr/bin/python
import ldap
import sys
import ldap.modlist as modlist
from datetime import datetime
import requests
import json
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import logging

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%d-%b-%y %H:%M:%S')
#logging.basicConfig(level=logging.ERROR, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%d-%b-%y %H:%M:%S')

hostname = 'https://idm1.mylab.test'
data_url = '/ipa/json'
login_url = '/ipa/session/login_password'
user = 'admin'
password = 'redhat12'

AD_LDAP_URL = 'ldaps://addc01.mylab.test'
AD_SEARCH_BASE = 'dc=mylab,dc=test'
AD_GROUP = "CN=RH-ADMINS,OU=Tier0 Security Groups,OU=Tier0,OU=CSC,DC=MYLAB,DC=TEST"
AD_QUERY = "(&(objectCategory=person)(objectclass=user)(memberOf:1.2.840.113556.1.4.1941:=" + AD_GROUP + "))"
AD_USER = 'idm_svc@mylab.test'
AD_USER_PASSWD = 'password'

def idm_search():
    logging.debug("============================ IdM Search ============================")
    all_users_uid = set()
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
    raw_data = request.post(hostname+data_url, data=json.dumps(user_search), headers=data_header)
    data = json.loads(raw_data.text)
    for idm_user in data['result']['result']:
        user_uid =str(idm_user['uid'])
        all_users_uid.add(user_uid)
    return all_users_uid


def search(ldap_uri, base, query, user, password):
    logging.debug("============================ AD Search ============================")
    uids = set()
    try:
        l = ldap.initialize(ldap_uri)
        l.protocol_version = ldap.VERSION3
        l.set_option(ldap.OPT_REFERRALS, 0)
        search_scope = ldap.SCOPE_SUBTREE
        #retrieve_attributes = ["sAMAccountName"]  ################ To be enabled
        retrieve_attributes = ["uid"]
        ldap_result_id = l.search(
            base,
            search_scope,
            query,
            retrieve_attributes
        )
        result_set = []
        while 1:
            result_type, result_data = l.result(ldap_result_id, 0)
            if (result_data == []):
                break
            else:
                if result_type == ldap.RES_SEARCH_ENTRY:
                    result_set.append(result_data)

        if len(result_set) == 0:
            print('No results found.')
            return
        logging.debug('%s', result_set)
        count = 0
        uid_max = 0
        for i in range(len(result_set)):
            for entry in result_set[i]:
                try:
                    print entry
                    uid = entry[1]['uid'][0]
                    #uid = entry[1]['sAMAccountName'][0]
                    count += 1
                    uids.add(uid)
                except:
                    logging.debug("sAMAccountName not found in attr", exc_info=True)
        print "pass =============="
    except ldap.LDAPError, e:
        logging.debug("LDAPError", exc_info=True)

    finally:
        l.unbind_s()
        logging.debug("Done, returning", exc_info=True)
        return(uids)


def create_user(user_id):
    logging.debug("============================ Create User ============================")
    logging.debug('Adding user %s', user_id)
    user_add = {
        "id": 0,
        "method": "user_add/1",
        "params": [
            [ user_id ],
            {
                "givenname": user_id,
                "sn": user_id,
                "loginshell": "/bin/bash",
                "gecos": "User from IdM",
                "ipauserauthtype": ["radius"],
#                "ipatokenradiusconfiglink": "My-Radius-Server", ######## To be added
                "version": "2.231"
            }
        ]
    }
    raw_data = request.post(hostname+data_url, data=json.dumps(user_add), headers=data_header)

def delete_user(user_id):
    logging.debug("============================ Delete User ============================")

    user_del = {
        "id": 0,
        "method": "user_del/1",
        "params": [
            [ user_id ],
            {
                "version": "2.231"
            }
        ]
    }
    raw_data = request.post(hostname+data_url, data=json.dumps(user_del), headers=data_header)
    data = json.loads(raw_data.text)



def main():
    global request
    global data_header
    request = requests.Session()
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    requests.packages.urllib3.disable_warnings()
    request.verify = False
    login_header = {'Referer': hostname + '/ipa', 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'text/plain'}
    data_header = {'Referer': hostname + '/ipa', 'Content-Type': 'application/json', 'Accept': 'text/json'}
    login_json = {'user': user, 'password': password}
    resp = request.post(hostname+login_url, data=login_json)
    IDM_USERS = idm_search()
    #IDM_USERS = search(IDM_LDAP_URL, IDM_DC_PATH, IDM_QUERY, IDM_USER, IDM_USER_PASSWD)
    #print IDM_USERS
    #AD_USERS = search(AD_LDAP_URL, AD_SEARCH_BASE, AD_QUERY, AD_USER, AD_USER_PASSWD, 'AD')
    AD_USERS = set(['cottyva', 'kibana', 'tier0_ea5049', 'tier0_ec19707', 'tier0_ec18068', 'rhtestuser', 'tier0_ukhalid', 'DHCPAdmin', 'dpetrella', 'ExchAdmin', 'jsiders', 'VMWareVDI', 'tier0_ec19533', 'tier0_ec14577', 'laker', 'tier0_ea3911', 'CAADmin', 'aj-admin', 'admin', 'Paul_ADM', 'nchaudhry', 'ADFSAdmin', 'manaitestuser', 'mwesterfield'])
    logging.debug("============================ IdM Users are %s  ============================", IDM_USERS)
    logging.debug("============================ AD Users are %s  ============================", AD_USERS)
    TO_ADD = AD_USERS.difference(IDM_USERS)
    TO_DEL = IDM_USERS.difference(AD_USERS)
    logging.debug("============================ Users to be deleted %s  ============================", TO_DEL)
    logging.debug("============================ Users to be added  %s  ============================", TO_ADD)
    delete_user('rbuzatu')
    create_user('rbuzatu')
    #for user in TO_ADD:
    #    create_user(user, uid)
    #for user in TO_DEL:
    #    delete_user(user)
    now = datetime.now()
    logging.debug("============================ Ran at %s ============================", now)


if __name__ == '__main__':
    sys.exit(main())
