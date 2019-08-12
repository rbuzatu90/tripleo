import ldap
import sys
import uuid
import ldap.modlist as modlist

IDM_LDAP_URL = 'ldaps://idm1.idm.mylab.test:636'
IDM_SEARCH_BASE = 'dc=kerb,dc=mylab,dc=test'
IDM_QUERY = '(uid=rbuz)'
IDM_USER = 'cn=directory manager'
IDM_USER_PASSWD = '*******'
IDM_DOMAIN = 'kerb.mylab.test'
IDM_REALM = IDM_DOMAIN.upper()
IDM_DC_PATH = 'dc=kerb,dc=mylab,dc=test'

def create_user(user_id):
    print 'Adding user', user_id
    user_uuid=str(uuid.uuid4())
    dn="uid=" + user_id + ",cn=users,cn=accounts,dc=kerb,dc=mylab,dc=test"
    user = {}
    user['displayName'] = user_id
    user['uid'] = user_id
    user['krbCanonicalName'] = user_id + IDM_REALM
    user['objectClass'] = ['top', 'person', 'organizationalperson', 'inetorgperson', 'inetuser', 'posixaccount', 'krbprincipalaux', 'krbticketpolicyaux', 'ipaobject', 'ipasshuser', 'ipaSshGroupOfPubKeys', 'mepOriginEntry']
    user['loginShell'] = '/bin/bash'
    user['initials'] = 'AD'
    user['gecos'] = user_id
    user['sn'] = user_id
    user['homeDirectory'] = '/home/'+ user_id
    user['mail'] = user_id + '@' + IDM_DOMAIN
    user['krbPrincipalName'] = user_id + '@' + IDM_REALM
    user['givenName'] = user_id
    user['cn'] = user_id + user_id
    user['ipaUniqueID'] = user_uuid
    user['uidNumber'] = '608600444'
    user['gidNumber'] = '608600444'
    #user['memberOf'] = ["'cn=ipausers,cn=groups,cn=accounts,' + dc_path"]
    user['memberOf'] = ['cn=ipausers,cn=groups,cn=accounts,dc=kerb,dc=mylab,dc=test', 'cn=itibiti2,cn=groups,cn=accounts,dc=kerb,dc=mylab,dc=test']
    ldif = modlist.addModlist(user)
    try:
        idm_ldap.add_s(dn, ldif)
    except ldap.LDAPError, e:
        if e.message['desc'] == 'Already exists':
            print "User", user_id, "already exists, nothing to add now"
        else:
            print 'dsa'
            print('LDAPError: %s.' % e)
    print 'done'
    
def main():
    #IDM_USERS = search(IDM_LDAP_URL, IDM_SEARCH_BASE, IDM_QUERY, IDM_USER, IDM_USER_PASSWD)
    #AD_USERS = search(AD_LDAP_URL, AD_SEARCH_BASE, AD_QUERY)
    AD_USERS={'unu', 'doi', 'trei', 'patru'}
    IDM_USERS={'trei', 'patru', 'cinci', 'jsmith2'}
    #print IDM_USERS, AD_USERS
    #print "IdM users are:", IDM_USERS
    #print "AD users are:", AD_USERS
    TO_ADD = AD_USERS.difference(IDM_USERS)
    TO_DEL = IDM_USERS.difference(AD_USERS)
    #print "Users to add", TO_ADD
    #print "Users tp del", TO_DEL
    global idm_ldap
    idm_ldap = ldap.initialize(IDM_LDAP_URL)
    idm_ldap.simple_bind_s(IDM_USER, IDM_USER_PASSWD)
    #for user in TO_ADD:
    #    create_user(user)
    #for user in TO_DEL:
    #    delete_user(user)
    delete_user('lolbau')
    create_user('lolbau')
    idm_ldap.unbind_s()


if __name__ == '__main__':
    sys.exit(main())

