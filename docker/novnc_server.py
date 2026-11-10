# Lance websockify (serveur web noVNC + proxy WebSocket) en ajoutant "Cache-Control: no-cache"
# à chaque réponse. Sans cet en-tête, les navigateurs gardent les fichiers de noVNC en cache
# pendant des semaines, et après une mise à jour de noVNC ils mélangent anciens et nouveaux
# fichiers ("does not provide an export named ..."). Avec no-cache, le navigateur revalide
# chaque fichier (réponse 304 s'il n'a pas changé).
from websockify import websocketproxy

_end_headers = websocketproxy.ProxyRequestHandler.end_headers


def end_headers(self):
    self.send_header("Cache-Control", "no-cache")
    _end_headers(self)


websocketproxy.ProxyRequestHandler.end_headers = end_headers
websocketproxy.websockify_init()
