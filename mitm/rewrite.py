import sys
from urllib.parse import urlencode, urlsplit

ignore_hosts = sys.argv[1:]

for line in sys.stdin:
    url = line.split(' ')[0]
    _, netloc, path, _, _ = urlsplit(url)
    ignore = False
    for host in ignore_hosts:
        if netloc in host:
            ignore = True
            break
    if path.endswith('.js') and not ignore:
        print('OK rewrite-url=http://127.0.0.1:13337?' + urlencode({'url': url, 'host': netloc}))
    else:
        print('ERR')
    sys.stdout.flush()
