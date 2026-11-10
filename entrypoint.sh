#!/bin/bash

VNC_PASSWORD="${VNC_PASSWORD:-twitch_miner}"
if [ ${#VNC_PASSWORD} -gt 8 ]; then
  echo "Warning: VNC only uses the first 8 characters of VNC_PASSWORD (\"${VNC_PASSWORD:0:8}\")" >&2
fi

# Recréé à chaque démarrage, pour qu'un changement de VNC_PASSWORD soit pris en compte
mkdir -p ~/.vnc
x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd >/dev/null 2>&1

rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

Xvfb :1 -screen 0 1280x800x24 -nolisten tcp &
# attendre que le serveur X soit prêt
for _ in $(seq 50); do
  [ -S /tmp/.X11-unix/X1 ] && break
  sleep 0.1
done

fluxbox >/dev/null 2>&1 &

# x11vnc et websockify sont relancés s'ils s'arrêtent : l'accès web ne reste jamais bloqué
(
  while true; do
    x11vnc -display :1 -forever -shared -usepw -localhost -rfbport 5900 -quiet
    echo "x11vnc stopped, restarting..." >&2
    sleep 2
  done
) &
(
  cd /opt/websockify || exit 1
  while true; do
    python novnc_server.py --web /opt/novnc 6080 localhost:5900 >/dev/null 2>&1
    echo "websockify stopped, restarting..." >&2
    sleep 2
  done
) &

exec python main.py
