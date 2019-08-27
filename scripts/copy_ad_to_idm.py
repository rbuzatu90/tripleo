#!/usr/bin/python
import ldap
import sys
import uuid
import ldap.modlist as modlist
from datetime import datetime

IDM_LDAP_URL = 'ldaps://idm1.mylab.test:636'
#IDM_SEARCH_BASE = 'dc=mylab,dc=test'
IDM_QUERY = '(&(objectClass=person))'
IDM_USER = 'cn=Directory Manager'
IDM_USER_PASSWD = 'password'
IDM_DOMAIN = 'mylab.test'
IDM_REALM = IDM_DOMAIN.upper()
IDM_DC_PATH = 'dc=mylab,dc=test'

AD_LDAP_URL = 'ldaps://test-ad'
AD_SEARCH_BASE = 'dc=ad-test,dc=test'
AD_GROUP = "CN=MY-USERS,OU=Tier0,OU=MY-GROUP,DC=AD_TEST,DC=TEST,"
AD_QUERY = "(&(objectCategory=person)(objectclass=user)(memberOf:1.2.840.113556.1.4.1941:=" + AD_GROUP + "))"
AD_USER = 'idm-user@ad-test.test'
AD_USER_PASSWD = 'password'

def search(ldap_uri, base, query, user, password, type):
    print 'Searching on', type, ldap_uri,  base, query
    uids = set()
    try:
        l = ldap.initialize(ldap_uri)
        l.protocol_version = ldap.VERSION3
        l.set_option(ldap.OPT_REFERRALS, 0)
        l.simple_bind_s(user, password)
        search_scope = ldap.SCOPE_SUBTREE
  	if type == 'AD':
            retrieve_attributes = ["sAMAccountName"]
	elif type == 'IdM':
	    retrieve_attributes = ['uidNumber', 'uid']
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
        count = 0
	uid_max = 0
        for i in range(len(result_set)):
            for entry in result_set[i]:
                try:
		    if type == 'AD':
                        uid = entry[1]['sAMAccountName'][0]
                        count += 1
                        uids.add(uid)
		    elif type == 'IdM':
			uid = entry[1]['uid'][0]
			if uid_max < entry[1]['uidNumber'][0]:
			    uid_max = entry[1]['uidNumber'][0]
			count += 1
			uids.add(uid)
                except:
                    pass
    except ldap.LDAPError, e:
        print('LDAPError: %s.' % e)

    finally:
        l.unbind_s()
	if type == 'AD':
            return(uids)
	elif type == 'IdM':
	    return(uids, uid_max)



def create_user(user_id, uid):
    print 'Adding user', user_id, 'with UID of', uid
    dn="uid=" + user_id + ",cn=users,cn=accounts," + IDM_DC_PATH
    user = {}
    user['displayName'] = user_id
    user['uid'] = user_id
    user['krbCanonicalName'] = user_id + "@" + IDM_REALM
    user['objectClass'] = ['top', 'person', 'organizationalperson', 'inetorgperson', 'inetuser', 'posixaccount', 'krbprincipalaux', 'krbticketpolicyaux', 'ipaobject', 'ipasshuser', 'ipaSshGroupOfPubKeys', 'mepOriginEntry', 'ipauserauthtypeclass', 'ipatokenradiusproxyuser']
    user['loginShell'] = '/bin/bash'
    user['initials'] = 'FromAD'
    user['gecos'] = user_id
    user['sn'] = user_id
    user['homeDirectory'] = '/home/'+ user_id
    user['mail'] = user_id + '@' + IDM_DOMAIN
    user['krbPrincipalName'] = user_id + '@' + IDM_REALM
    user['givenName'] = user_id
    user['cn'] = user_id + user_id
    user['uidNumber'] = str(uid)
    user['gidNumber'] = str(uid)
    user['description'] = 'FromAD'
    user['ipaUserAuthType'] = 'radius'
    user['ipatokenRadiusConfigLink'] = 'cn=RSA-Radius,cn=radiusproxy,dc=mylab,dc=test'
    ldif = modlist.addModlist(user)
    try:
        idm_ldap.add_s(dn, ldif)
    except ldap.LDAPError, e:
        if e.message['desc'] == 'Already exists':
            print "User", user_id, "already exists, nothing to add now"
        else:
            print('LDAPError: %s.' % e)
    else:
        print 'User added'

def delete_user(user_id):
    deleteDN = 'uid=' + user_id + ',cn=users,cn=accounts,' + IDM_DC_PATH
    try:
	if user_id == 'admin' or user_id == 'rhtestuser' :
	    print 'Not deleting ' + user_id + ' user'
    	    pass
        else:
    	    print "Deleting user", user_id
            idm_ldap.delete_s(deleteDN)
    except ldap.LDAPError, e:
        if e.message['desc'] == 'No such object':
            print "User", user_id, "doesn't exists, nothing to delete now"
        else:
            print('LDAPError: %s.' % e)



def main():
    IDM_USERS = search(IDM_LDAP_URL, IDM_DC_PATH, IDM_QUERY, IDM_USER, IDM_USER_PASSWD, 'IdM')
    AD_USERS = search(AD_LDAP_URL, AD_SEARCH_BASE, AD_QUERY, AD_USER, AD_USER_PASSWD, 'AD')
    print "IdM users are:", IDM_USERS[0], 'and max uuid is', IDM_USERS[1]
    print "AD users are:", AD_USERS
    TO_ADD = AD_USERS.difference(IDM_USERS[0])
    TO_DEL = IDM_USERS[0].difference(AD_USERS)
    print "Users to add", TO_ADD
    print "Users to del", TO_DEL
    global idm_ldap
    idm_ldap = ldap.initialize(IDM_LDAP_URL)
    idm_ldap.simple_bind_s(IDM_USER, IDM_USER_PASSWD)
    uid = int(IDM_USERS[1])
    for user in TO_ADD:
        uid += 1
        create_user(user, uid)
    for user in TO_DEL:
        delete_user(user)
    idm_ldap.unbind_s()
    now = datetime.now()
    print 'We finished running at', now
    print '----------------------------'


if __name__ == '__main__':
    sys.exit(main())
