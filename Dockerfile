# Use a base image with Python
FROM python:3.8

# Set the working directory in the container
WORKDIR /usr/src/app

# Install system dependencies required for PyGObject, graphical environment, and AppIndicators
RUN apt-get update && apt-get install -y \
    libgirepository1.0-dev \
    libcairo2-dev \
    pkg-config \
    python3-dev \
    gtk+3.0 \
    dbus-x11 \
    x11vnc \
    xvfb \
    fluxbox \
    net-tools \
    libappindicator3-dev \
    libayatana-appindicator3-dev \
    x11-utils # x11-utils for xdpyinfo

# Copy the requirements.txt file and install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the project files
COPY . .

# Set an environment variable for the VNC password with a default value
ENV VNC_PASSWORD=twitch_miner

# Set up VNC server
RUN mkdir ~/.vnc
# Use the VNC_PASSWORD environment variable to set the VNC password
RUN x11vnc -storepasswd $VNC_PASSWORD ~/.vnc/passwd

# Start Xvfb, Fluxbox, and x11vnc, then run the application
CMD rm -f /tmp/.X1-lock && \
    Xvfb :1 -screen 0 1024x768x16 & \
    fluxbox & \
    # Wait for the X server to be up
    while ! xdpyinfo -display :1 > /dev/null 2>&1; do \
        echo "Waiting for X server to be available..."; \
        sleep 1; \
    done && \
    echo "X server is running" || (echo "X server failed to start, exiting..." && exit 1); \
    # Start x11vnc with additional logging
    x11vnc -display :1 -nopw -listen 0.0.0.0 -xkb -no6 -noxdamage -o /var/log/x11vnc.log & \
    # Explicitly set the DISPLAY variable for the Python application
    export DISPLAY=:1 && python main.py 2>&1 | tee /var/log/main.log
