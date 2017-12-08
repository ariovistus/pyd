import os
import json

tag = os.environ.get('TRAVIS_TAG', '')
if tag != '':
    with open('version.txt') as f1:
        a = f1.read().strip()
    if 'v' + a != tag:
        version = tag
        if version.startswith('v'): 
            version = version[1:]
        print("version.txt version [v]%s doesn't match tag %s - setting to %s" % (a, tag, version))
        with open('version.txt', 'w') as f2:
            f2.write(version)
