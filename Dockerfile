FROM ubuntu:18.04

User root

WORKDIR /root/workdir
COPY dunst /root/workdir/dunst

ARG PREFIX=/usr
ARG SYSTEMD=1
ARG SERVICEDIR_SYSTEMD=/usr/lib/systemd/user
ARG SERVICEDIR_DBUS=/usr/share/dbus-1/services


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
&&  make -j$(grep -i processor /proc/cpuinfo | wc -l) \
      PREFIX="${PREFIX}" \
      SYSTEMD="${SYSTEMD}" \ 
      SERVICEDIR_SYSTEMD="${SERVICEDIR_SYSTEMD}" \
      SERVICEDIR_DBUS="${SERVICEDIR_DBUS}" \
&&  make \
      PREFIX="${PREFIX}" \
      SYSTEMD="${SYSTEMD}" \ 
      SERVICEDIR_SYSTEMD="${SERVICEDIR_SYSTEMD}" \
      SERVICEDIR_DBUS="${SERVICEDIR_DBUS}" \
      install \
&&  cd /usr \
&&  tar --remove-files -czf /root/workdir/dunst.tar.gz \
      lib/systemd/user/dunst.service \
      share/man/man1/dunstctl.1 \
      share/man/man1/dunst.1 \
      share/dunst/dunstrc \
      share/dbus-1/services/org.knopwob.dunst.service \
      bin/dunstify \
      bin/dunst \
      bin/dunstctl \
&&  cd /root/workdir \
&&  rm -rf dunst

