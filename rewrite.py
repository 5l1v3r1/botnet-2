import sys
from urllib.parse import urlencode, urlsplit

ignore_hosts = sys.argv[1:]

# with open('/var/log/squid/wat', 'w') as f:
#     f.write(repr(ignore_hosts))

for line in sys.stdin:
    url = line.split(' ')[0]
    _, netloc, path, _, _ = urlsplit(url)
    if path.endswith('.js') and netloc not in ignore_hosts:
        print('OK rewrite-url=http://127.0.0.1:13337?' + urlencode({'url': url, 'host': netloc}))
    else:
        print('ERR')
    sys.stdout.flush()
