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


if __name__ == '__main__':
    main()
