import sys
from urllib.parse import urlencode, urlsplit

ignore = sys.argv[1]

for line in sys.stdin:
    url = line.split(' ')[0]
    scheme, netloc, path, query, fragment = urlsplit(url)
    if path.endswith('.js') and netloc != ignore:
        q = {
            'scheme': scheme,
            'netloc': netloc,
            'rest': path + query + fragment,
            }
        print('OK rewrite-url=http://127.0.0.1:13337?' + urlencode(q))
    else:
        print('ERR')
    sys.stdout.flush()
