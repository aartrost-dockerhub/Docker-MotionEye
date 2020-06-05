FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV MOTIONEYE_VERSION="0.42"

# Install motion, ffmpeg, v4l-utils and the dependencies from the repositories
RUN apt-get update \
    && apt-get -y -f install \
        software-properties-common \
    && add-apt-repository universe \
    && apt-get update \
    && apt-get -y -f install \
        wget \
        ffmpeg \
        v4l-utils \
        tzdata \
        python2 \
        python2-dev \
        nano \
        gifsicle \
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
        libmicrohttpd-dev \
     && apt-get clean

# install pip2
RUN curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py \
    && python2 get-pip.py

# Install latest motion from git
RUN cd ~ \
    && git clone https://github.com/Motion-Project/motion.git \
    && cd motion \
    && autoreconf -fiv \
    && ./configure \
    && make \
    && make install

# Install latest mp4fpsmod (can be used to fix stutter issues on passthrough videos with variable framerate)
RUN cd ~ \
    && git clone https://github.com/nu774/mp4fpsmod \
    && cd mp4fpsmod \
    && ./bootstrap.sh \
    && ./configure \
    && make \
    && strip mp4fpsmod \
    && make install

# Install motioneye, which will automatically pull Python dependencies (tornado, jinja2, pillow and pycurl)
RUN pip2 install motioneye==$MOTIONEYE_VERSION

# Prepare the configuration directory and the media directory
RUN mkdir -p /etc/motioneye \
    mkdir -p /var/lib/motioneye

# custom stuff for personal use
RUN pip3 install numpy requests pysocks pillow

# Configurations, Video & Images
VOLUME ["/etc/motioneye", "/var/lib/motioneye"]

# Run migration helper to convert config from motion 3.x to 4.x, set default conf and start the MotionEye Server
CMD for file in `find /etc/motioneye -type f \( -name "motion.conf" -o -name "thread-*.conf" \)`; do /usr/local/lib/python2.7/dist-packages/motioneye/scripts/migrateconf.sh $file; done; \
    test -e /etc/motioneye/motioneye.conf || \
    cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf; \
    /usr/local/bin/meyectl startserver -c /etc/motioneye/motioneye.conf

EXPOSE 8765