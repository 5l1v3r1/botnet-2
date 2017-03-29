import sys
from urllib.parse import urlencode, urlsplit

ignore = sys.argv[1]

for line in sys.stdin:
    url = line.split(' ')[0]
    _, netloc, path, _, _ = urlsplit(url)
    if path.endswith('.js') and netloc != ignore:
        print('OK rewrite-url=http://127.0.0.1:13337?' + urlencode({'url': url, 'host': netloc}))
    else:
        print('ERR')
    sys.stdout.flush()
