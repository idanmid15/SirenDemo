
from http.server import BaseHTTPRequestHandler, HTTPServer


class S(BaseHTTPRequestHandler):
    def do_GET(self):
        # Send response status code
        self.send_response(200)

        # Send headers
        self.send_header('Content-type', 'application/json')
        self.end_headers()

        # Send message back to client
        credit_cards = ["1234-1235-5643-7364", "3345-1345-7649-4363", "1111-1235-5643-7364", "1234-1235-5673-7464"]
        json = {"credit_cards": credit_cards}
        # Write content as utf-8 data
        self.wfile.write(bytes(str(json), "utf8"))
        return


def run(server_class=HTTPServer, handler_class=S, port=8075):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print("Started serving on localhost:{}".format(port))
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()


if __name__ == '__main__':
    run()
