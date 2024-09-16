from http.server import BaseHTTPRequestHandler, HTTPServer

class myHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"Hello MST 300!")

def run (server_class=HTTPServer, hanler_class=myHandler, port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, hanler_class)
    print(f'Server running on port {port}')
    httpd.serve_forever()

if __name__ == '__main__':
    run()