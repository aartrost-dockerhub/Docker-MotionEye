FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV MOTIONEYE_VERSION="0.41"

# Install motion, ffmpeg, v4l-utils and the dependencies from the repositories
RUN apt-get update && \
    apt-get -y -f install \
        wget \
        ffmpeg \
        v4l-utils \
        tzdata \
        python-pip \
        python-dev \
        python3 \
        python3-pip \
        curl \
        libssl-dev \
        libcurl4-openssl-dev \
        libjpeg-dev \
        git \
        autoconf \
        automake \
        build-essential \
        gettext \
        autopoint \
        pkgconf \
        libtool \
        libzip-dev \
        libjpeg-dev \
        libavformat-dev \
        libavcodec-dev \
        libavutil-dev \
        libswscale-dev \
        libavdevice-dev \
        libwebp-dev \
        libmicrohttpd-dev && \
     apt-get clean

# Install latest motion from git
RUN cd ~ \
    && git clone https://github.com/Motion-Project/motion.git \
    && cd motion \
    && autoreconf -fiv \
    && ./configure \
    && make \
    && make install

# Install motioneye, which will automatically pull Python dependencies (tornado, jinja2, pillow and pycurl)
RUN pip install motioneye==$MOTIONEYE_VERSION

# Prepare the configuration directory and the media directory
RUN mkdir -p /etc/motioneye \
    mkdir -p /var/lib/motioneye

# custom stuff for personal use
pip3 install numpy requests

# Configurations, Video & Images
VOLUME ["/etc/motioneye", "/var/lib/motioneye"]

# Run migration helper to convert config from motion 3.x to 4.x, set default conf and start the MotionEye Server
CMD for file in `find /etc/motioneye -type f \( -name "motion.conf" -o -name "thread-*.conf" \)`; do /usr/local/lib/python2.7/dist-packages/motioneye/scripts/migrateconf.sh $file; done; \
    test -e /etc/motioneye/motioneye.conf || \
    cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf; \
    /usr/local/bin/meyectl startserver -c /etc/motioneye/motioneye.conf

EXPOSE 8765