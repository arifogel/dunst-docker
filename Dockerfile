FROM ubuntu:18.04

User root

WORKDIR /root/workdir
COPY dunst /root/workdir/dunst

RUN apt-get update && apt-get install -y \
    git \
    libdbus-1-dev \
    libx11-dev \
    libxinerama-dev \
    libxrandr-dev \
    libxss-dev \
    libglib2.0-dev \
    libpango1.0-dev \ 
    libgtk-3-dev \
    libxdg-basedir-dev \
    libnotify-dev \
&&  rm -rf /var/lib/apt/lists/* \
&&  apt-get clean

RUN apt-get update && apt-get install -y \
    systemd \
&&  rm -rf /var/lib/apt/lists/* \
&&  apt-get clean

RUN cd /root/workdir/dunst \
&&  bash -c 'make -j$(grep -i processor /proc/cpuinfo | wc -l)' PREFIX=/root/workdir/prefix/usr/local SYSTEMD=1 SERVICEDIR_SYSTEMD=/root/workdir/prefix/usr/local/lib/systemd/user SERVICEDIR_DBUS=/root/workdir/prefix/usr/local/share/dbus-1/services \
&&  make PREFIX=/root/workdir/prefix/usr/local SYSTEMD=1 SERVICEDIR_SYSTEMD=/root/workdir/prefix/usr/local/lib/systemd/user SERVICEDIR_DBUS=/root/workdir/prefix/usr/local/share/dbus-1/services install \
&&  cd /root/workdir/prefix \
&&  tar -czf /root/workdir/dunst.tar.gz usr \
&&  cd /root/workdir \
&&  rm -rf prefix dunst

