#!/usr/bin/python
from jenkinsapi.jenkins import Jenkins
from jenkinsapi.build import Build
import argparse

import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

JENKINS_URL='https://mastern-jenk.apps.ocp-c1.prod.xxx.com'
#FLEXY_JOB='Launch Environment Flexy'
FLEXY_JOB='ocp-common/Flexy-install'

def parse_args():
    parser = argparse.ArgumentParser(description="Flexy job build searcher")
    parser.add_argument("-u", "--user", help="Search this user's builds")
    parser.add_argument("-p", "--inparam", help="Search this word in parameters")
    parser.add_argument("-s", '--success-only', dest='success_only', action='store_true',  help="Will show only not running builds that ended with SUCCESS status")

    return parser.parse_args()

def get_user_from_causes(build):
    for cause in build.get_causes():
        if cause.get('_class', None) == 'hudson.model.Cause$UserIdCause':
            return cause.get('userId')
    return None

def build_triggered_by_user(build, user):
    build_name = build._data['displayName']
    return user == build_name or user == get_user_from_causes(build)

def main():
    args = parse_args()

    user = args.user
    inparam = args.inparam
    success_only = args.success_only

    jenkins = Jenkins(JENKINS_URL, ssl_verify=False, timeout=300)
    job = jenkins[FLEXY_JOB]
    # print(job)

    builds = job._data['builds']

    for b in builds:
        url = b['url']
        num = b['number']

        try:
            build = Build(url, num, job)
        except KeyboardInterrupt as e:
            raise e
        except:
            continue

        if (user is None or build_triggered_by_user(build, user)) and (not success_only or build.is_good()):
            printable_args = [] 
            params = build.get_params()

            if inparam is not None:
                for k,v in params.items():
                    if v is not None and inparam.lower() in v.lower():
                        printable_args.append('\t {0}:\n\t\t{1}'.format(k, v.replace('\n', '\n\t\t')))

            if inparam is None or len(printable_args) > 0:
                print('User: {0} {1} ({2})'.format(build._data['displayName'], build.get_number(), build.get_status()))
                print('\t PREFIX: {0}'.format(params['INSTANCE_NAME_PREFIX']))
                print('\t TEMPLATE: {0}'.format(params['VARIABLES_LOCATION']))
                print('\t URL: {0}'.format(url))
                if len(printable_args) > 0:
                    print('      Params found:')
                    for printable_arg in printable_args:
                        print(printable_arg)
                print('')

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Search Interrupted')
