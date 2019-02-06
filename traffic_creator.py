
import http.client
import time
import sys


def create_traffic(url):
    while True:
        conn = http.client.HTTPConnection(url)
        conn.request("GET", "/productpage")
        res = conn.getresponse()
        print(res.status, res.reason)
        time.sleep(0.5)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("usage: {} gateway_url".format(sys.argv[0]))
        sys.exit(-1)
    product_page_url = sys.argv[1]
    create_traffic(product_page_url)
