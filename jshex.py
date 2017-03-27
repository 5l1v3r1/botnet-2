import sys
sys.stdout.write("eval('")
for chunk in sys.stdin:
    for c in chunk:
        sys.stdout.write(r'\x{0:02x}'.format(ord(c)))
sys.stdout.write("');")
