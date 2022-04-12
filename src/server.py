# Python 3 server example
from http.server import BaseHTTPRequestHandler, HTTPServer
import socket
import time
import os


hostName = "0.0.0.0"
serverPort = 80

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(bytes("<html><head><title>debug me</title></head>", "utf-8"))
        self.wfile.write(bytes("<p><b>Hello Azure Container Apps!.</b></p>", "utf-8"))
        self.wfile.write(bytes("<p><b>Hostname:</b> %s</p>" % socket.gethostname(), "utf-8"))
        environ = ""
        for item, value in os.environ.items():
            environ += '<br>     {}: {} <br>'.format(item, value)
        self.wfile.write(bytes("<p><b>Environment Variables:</b> %s</p>" % environ, "utf-8"))
        self.wfile.write(bytes("</body></html>", "utf-8"))


if __name__ == "__main__":        
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")# Python 3 server example
