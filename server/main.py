from id import IDGenerator
from handler import GameServerHandler
from server import GameServer

if __name__ == "__main__":
    s = GameServer(GameServerHandler)
    s.run()