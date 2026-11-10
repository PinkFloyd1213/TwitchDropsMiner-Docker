# syntax=docker/dockerfile:1

# Étape 1 : récupérer noVNC + websockify (aucun outil de téléchargement dans l'image finale)
FROM python:3.13-slim AS novnc

ARG NOVNC_VERSION=1.7.0
ARG WEBSOCKIFY_VERSION=0.13.0

ADD https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz /tmp/novnc.tar.gz
ADD https://github.com/novnc/websockify/archive/refs/tags/v${WEBSOCKIFY_VERSION}.tar.gz /tmp/websockify.tar.gz

RUN mkdir -p /opt/novnc /opt/websockify \
    && tar -xzf /tmp/novnc.tar.gz -C /opt/novnc --strip-components=1 \
    && tar -xzf /tmp/websockify.tar.gz -C /opt/websockify --strip-components=1 \
    && rm -rf /opt/novnc/docs /opt/novnc/tests /opt/novnc/snap /opt/novnc/utils \
    # http://<hôte>:6080/ ouvre directement le client, connexion auto + reconnexion auto
    && printf '<!DOCTYPE html><meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&reconnect=true&resize=scale">\n' \
        > /opt/novnc/index.html


# Étape 2 : image finale
FROM python:3.13-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Chromium sert au login Twitch ; fonts-dejavu-core et fonts-symbola (emojis de l'interface) à l'affichage
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb x11vnc fluxbox chromium fonts-dejavu-core fonts-symbola tini \
    && rm -rf /var/lib/apt/lists/* \
    # pas de fond d'écran : évite la fenêtre d'erreur de fluxbox (fbsetbg)
    && ln -s /bin/true /usr/local/bin/fbsetbg

WORKDIR /usr/src/app

# Dépendances Python (PyGObject ne sert qu'à l'icône de la barre système, inutile ici)
COPY requirements.txt ./
RUN grep -v PyGObject requirements.txt > /tmp/requirements.txt \
    && pip install -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

COPY --from=novnc /opt/novnc /opt/novnc
COPY --from=novnc /opt/websockify /opt/websockify
COPY docker/novnc_server.py /opt/websockify/novnc_server.py
COPY --chmod=755 entrypoint.sh /entrypoint.sh

COPY . .

ENV DISPLAY=:1
# Dossier des données persistantes (cookies.jar, settings.json, cache...)
ENV TDM_DATA_DIR=/data
RUN mkdir -p /data

EXPOSE 6080

HEALTHCHECK --interval=1m --timeout=10s --start-period=1m --retries=3 CMD python -c "\
import socket, urllib.request; \
urllib.request.urlopen('http://127.0.0.1:6080/vnc.html', timeout=5); \
socket.create_connection(('127.0.0.1', 5900), timeout=5).close()"

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
