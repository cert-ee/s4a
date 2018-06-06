#!/usr/bin/python

'''
Run salt states for configured detector components daily
'''

import sys
import logging
import requests

logging.basicConfig(level=logging.ERROR,
                    format='%(asctime)s %(levelname)s %(message)s',
                    filename='/var/log/salt/minion', filemode='a')

# Import salt.client after logging.basicConfig,
# so that salt wouldn't override the logging settings
import salt.client

def main():
    caller = salt.client.Caller()
    api = caller.cmd('pillar.get', 'detector:api', {'host': '127.0.0.1', 'port': 4000})
    api_url = 'http://{0}:{1}/api/components'.format(api['host'], api['port'])
    api_upgrade = 'http://{host}:{port}/api/components/autoupgrade'.format(api['host'], api['port'])

    try:
        autoupgrade = requests.get(api_upgrade)
    except requests.exceptions.RequestException as e:
        logging.error('Could not communicate with detector API(%s) because: %s', api_upgrade, e)
        sys.exit(1)
    
    # If auto upgrade is set to true in the webinterface then run states
    if autoupgrade.json()['enabled']:
        try:
            components = requests.get(api_url)
        except requests.exceptions.RequestException as e:
            logging.error('Could not communicate with detector API(%s) because: %s', api_url, e)
            sys.exit(1)

        for comp in components.json():
            if comp['enabled'] and comp['installed'] and comp['name'] != 'evebox-agent':
                logging.info('Running state detector/%s', comp['name'])
                output = caller.cmd('state.apply', 'detector/{0}'.format(comp['name']))
                logging.info('Ran state detector/%s with result: %s', comp['name'], output)

        cron_output = caller.cmd('state.apply', 'detector/cron')
        logging.info('Ran state detector/cron with result: %s', cron_output)
    else:
        logging.info('Auto upgrade is not enabled in the web interface. Not doing anything')


if __name__ == '__main__':
    main()
