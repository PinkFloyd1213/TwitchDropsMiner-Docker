#!/bin/bash

mkdir -p ~/.vnc

if [ ! -f ~/.vnc/passwd ]; then
  x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
fi

rm -f /tmp/.X1-lock

Xvfb :1 -screen 0 1024x768x16 &
sleep 2

fluxbox &
x11vnc -display :1 -forever -usepw -shared -rfbport 5900 &
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

export DISPLAY=:1
exec python main.py

