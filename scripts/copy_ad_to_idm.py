import ldap
import sys

IDM_LDAP_URI = 'ldaps://idm1.idm.mylab.test'
IDM_SEARCH_BASE = 'dc=kerb,dc=mylab,dc=test'
IDM_QUERY = '(&(objectClass=person))'

AD_LDAP_URI = 'ldaps://idm1.idm.mylab.test'
AD_SEARCH_BASE = 'dc=kerb,dc=mylab,dc=test'
AD_QUERY = '(&(objectClass=person))'

def ldap_search(ldap_uri, base, query):
    uids = set()
    try:
        l = ldap.initialize(ldap_uri)
        l.protocol_version = ldap.VERSION3

        search_scope = ldap.SCOPE_SUBTREE
        retrieve_attributes = None

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
        for i in range(len(result_set)):
            for entry in result_set[i]:
                try:
                    uid = entry[1]['uid'][0]
                    count += 1
                    uids.add(uid)
                except:
                    pass
    except ldap.LDAPError, e:
        print('LDAPError: %s.' % e)

    finally:
        l.unbind_s()
        return(uids)


def create_user(uid):
    print "Creating user", uid


def delete_user(uid):
    print "Deleting user", uid


def main():
    IDM_USERS = ldap_search(IDM_LDAP_URI, IDM_SEARCH_BASE, IDM_QUERY)
    AD_USERS = ldap_search(AD_LDAP_URI, AD_SEARCH_BASE, AD_QUERY)
    print IDM_USERS, AD_USERS
    print "\n\n"
    AD_USERS={'unu', 'doi', 'trei', 'patru'}
    IDM_USERS={'trei', 'patru', 'cinci', 'sase'}
    print "IdM users are:", IDM_USERS
    print "AD users are:", AD_USERS
    TO_ADD = AD_USERS.difference(IDM_USERS)
    TO_DEL = IDM_USERS.difference(AD_USERS)
    print "Users to add", TO_ADD
    print "Users tp del", TO_DEL
    for user in TO_ADD:
        create_user(user)
    for user in TO_DEL:
        delete_user(user)


if __name__ == '__main__':
    sys.exit(main())
