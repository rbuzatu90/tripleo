#!/usr/bin/python
#/var/spool/foreman-proxy/openscap/arf/
#/var/lib/foreman-proxy/openscap/reports/arf/
#curl -k -u $USER:$PASS "https://localhost/api/v2/compliance/arf_reports/?per_page=180&page=10"
#for i in {1..11}; do  curl -k -u $USER:$PASS "https://localhost/api/v2/compliance/arf_reports/?per_page=18400&page=$i&full_results=true" > all_scap$i;done
#datetime.datetime.strptime(user['krbPasswordExpiration'][0], '%Y%m%d%H%M%SZ')

import json
import urllib2
import base64
import datetime

url = 'https://localhost/api/v2/compliance/arf_reports/'
page_size = '?per_page=1000'
username = 'admin'
password= 'passwd'
time_limit = 30 # time limit in days

def get_data()
    request = urllib2.Request(url)
    b64auth = base64.standard_b64encode("%s:%s" % (username,password))
    request.add_header("Authorization", "Basic %s" % b64auth)
    result = urllib2.urlopen(request)
    data = json.load(result)
    total = data['total']
    print total


def delete_record(record_id)
    print "deleting record"


def process_data(records)
    with open('scap_reports', 'r') as infile:
        data = json.load(infile)
        #for i in data['results']:
        #    print i['created_at'], i['id']
        results = data['results']
        now = datetime.datetime.now()
        for i in results:
            #print "record created at", data['results'][0]['created_at']
        #now = datetime.datetime.now().strftime("%d %b %Y %H:%M:%S")   #27 Aug 2019 11:55:12
        #now2 = datetime.datetime.now().strftime("%Y-%m-%d %H:%M%S UTC")
        #print now, now2
            created_date = datetime.datetime.strptime(i['created_at'], '%Y-%m-%d %H:%M:%S UTC' )
            delta = now - created_date
            #print delta.days - time_limit
            if delta.days > time_limit:
                print "To be deleted as they are", delta.days, "old"
                print i['id'], i['created_at']
            else:
                print 'Records are recent, only', delta.days, "old"


def main():
    raw_data = get_data()
    processed_data = process_data(raw_data)
    delete_record(processed_data)


if __name__ == '__main__':
    sys.exit(main())

# 2019-08-27 06:53:05 UTC
