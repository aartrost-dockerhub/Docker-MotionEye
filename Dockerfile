FROM debian:buster-slim
LABEL maintainer="Marcus Klein <himself@kleini.org>"

ENV MOTIONEYE_VERSION="0.42.1"

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="extra/Dockerfile" \
    org.label-schema.license="GPLv3" \
    org.label-schema.name="motioneye" \
    org.label-schema.url="https://github.com/ccrisan/motioneye/wiki" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/ccrisan/motioneye.git"

# By default, run as root.
ARG RUN_UID=0
ARG RUN_GID=0

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -t stable --yes --option Dpkg::Options::="--force-confnew" --no-install-recommends install \
      curl \
      ffmpeg \
      libmicrohttpd12 \
      libpq5 \
      lsb-release \
      mosquitto-clients \
      python-jinja2 \
      python-pil \
      python-pip \
      python-pip-whl \
      python-pycurl \
      python-setuptools \
      python-tornado \
      python-tz \
      python-wheel \
      v4l-utils \
      # custom packages
      nano \
      tzdata \
      git \
      automake \
      autoconf \
      autopoint \
      libtool \
      pkgconf \
      build-essential \
      libzip-dev \
      libjpeg62-turbo-dev \
      libmicrohttpd-dev \
      default-libmysqlclient-dev \
      gettext \
      gifsicle \
      libavformat-dev \
      libavcodec-dev \
      libavutil-dev \
      libswscale-dev \
      libavdevice-dev

# Install latest motion from git
RUN cd ~ \
    && git clone https://github.com/Motion-Project/motion.git \
    && cd motion \
    && autoreconf -fiv \
    && ./configure \
    && make \
    && make install \
    && rm -r ~/motion

    # Change uid/gid of user/group motion to match our desired IDs.  This will
    # make it easier to use execute motion as our desired user later.
RUN sed -i -e "s/^\(motion:[^:]*\):[0-9]*:[0-9]*:\(.*\)/\1:${RUN_UID}:${RUN_GID}:\2/" /etc/passwd && \
    sed -i -e "s/^\(motion:[^:]*\):[0-9]*:\(.*\)/\1:${RUN_GID}:\2/" /etc/group && \
    # install motioneye
    pip install motioneye==$MOTIONEYE_VERSION

# custom stuff for personal use
RUN pip install numpy requests pysocks pillow

# Install latest mp4fpsmod (can be used to fix stutter issues on passthrough videos with variable framerate)
RUN cd ~ \
    && git clone https://github.com/nu774/mp4fpsmod \
    && cd mp4fpsmod \
    && ./bootstrap.sh \
    && ./configure \
    && make \
    && strip mp4fpsmod \
    && make install \
    && rm -r ~/mp4fpsmod

# Cleanup
RUN apt-get purge --yes python-setuptools python-wheel git automake autoconf autopoint libtool pkgconf gettext build-essential libzip-dev libjpeg62-turbo-dev libmicrohttpd-dev && \
    apt-get autoremove --yes && \
    apt-get --yes clean && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# R/W needed for motioneye to update configurations
VOLUME /etc/motioneye

# Video & images
VOLUME /var/lib/motioneye

# set default conf and start the MotionEye Server
CMD test -e /etc/motioneye/motioneye.conf || \
    cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf; \
    # We need to chown at startup time since volumes are mounted as root. This is fugly.
    chown motion:motion /var/run /var/log /etc/motioneye /var/lib/motioneye /usr/local/share/motioneye/extra ; \
    su -g motion motion -s /bin/bash -c "/usr/local/bin/meyectl startserver -c /etc/motioneye/motioneye.conf"

EXPOSE 8765
