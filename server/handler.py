
from http.server import BaseHTTPRequestHandler
# from socketserver import _RequestType, BaseServer

class GameServerHandler(BaseHTTPRequestHandler):
    
    def do_GET(self):
        print("Get request....")
        self.send_response(200)
        self.send_header("content-type", "text/text")
        self.end_headers()
        msg = "Message from Get request"
        self.wfile.write(bytes(msg, "utf8"))
    
    def do_POST(self):
        print("Post request....")
        self.send_response(200)
        self.send_header("content-type", "text/text")
        self.end_headers()
        msg = "Message from Post request"
        self.wfile.write(bytes(msg, "utf8"))