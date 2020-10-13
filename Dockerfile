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
      wget \
      nano \
      python3-pip \
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
      libjpeg-turbo8 \
      libjpeg-turbo8-dev \
      libmicrohttpd-dev \
      default-libmysqlclient-dev \
      gettext \
      gifsicle \
      libavformat-dev \
      libavcodec-dev \
      libavutil-dev \
      libswscale-dev \
      libavdevice-dev && \
    # Install VAAPI drivers for hardware en/decoding
    echo "deb http://http.us.debian.org/debian buster main contrib non-free" >>/etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get --yes --option Dpkg::Options::="--force-confnew" --no-install-recommends install \
      intel-media-va-driver-non-free \
      i965-va-driver-shaders

# Install latest motion from git
RUN cd ~ \
    && git clone https://github.com/Motion-Project/motion.git \
    && cd motion \
    && autoreconf -fiv \
    && ./configure \
    && make \
    && make install \
    && rm -r ~/motion

# install motioneye & custom stuff for personal use
RUN pip install motioneye==$MOTIONEYE_VERSION 
RUN pip3 install numpy requests pysocks pillow

# Cleanup
RUN apt-get purge --yes python-setuptools python-wheel python3-pip git automake autoconf autopoint libtool pkgconf gettext build-essential libzip-dev libjpeg62-turbo-dev libmicrohttpd-dev && \
    apt-get autoremove --yes && \
    apt-get --yes clean && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# R/W needed for motioneye to update configurations
VOLUME /etc/motioneye

# Video & images
VOLUME /var/lib/motioneye

# set default conf and start the MotionEye Server
CMD test -e /etc/motioneye/motioneye.conf || \
    cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf; \
    /usr/local/bin/meyectl startserver -c /etc/motioneye/motioneye.conf

EXPOSE 8765
