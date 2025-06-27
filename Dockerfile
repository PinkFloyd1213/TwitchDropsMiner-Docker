FROM python:3.10

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    libgirepository1.0-dev libcairo2-dev pkg-config python3-dev \
    gtk+3.0 dbus-x11 libcanberra-gtk-module \
    x11vnc xvfb fluxbox wget unzip curl \
    libayatana-appindicator3-dev gir1.2-ayatanaappindicator3-0.1 \
    && apt-get clean

# Installer les dépendances Python
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Télécharger noVNC + websockify
RUN mkdir -p /opt/novnc && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.zip -o /tmp/novnc.zip && \
    unzip /tmp/novnc.zip -d /opt && \
    mv /opt/noVNC-1.4.0/* /opt/novnc && \
    curl -L https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.zip -o /tmp/ws.zip && \
    unzip /tmp/ws.zip -d /opt && \
    mv /opt/websockify-0.11.0 /opt/novnc/utils/websockify

COPY . .

# Copie du script d’entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV DISPLAY=:1
ENTRYPOINT ["/entrypoint.sh"]

