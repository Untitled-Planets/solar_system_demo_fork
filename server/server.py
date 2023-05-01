from http.server import HTTPServer
from handler import GameServerHandler

class GameServer:
    def __init__(self, p_handler: GameServerHandler) -> None:
        self._handler = p_handler
        pass

    def run(self) -> None:
        with HTTPServer(("localhost", 6969), self._handler) as server:
            server.serve_forever()
            server.server_close()
