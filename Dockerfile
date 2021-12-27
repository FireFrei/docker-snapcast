FROM alpine:latest

# Note: Build shairport-sync with metadata, stdout and pipe support (apk repo is without)
#   APK way: `RUN apk add shairport-sync --update --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing`
RUN apk add git build-base autoconf automake libtool alsa-lib-dev libdaemon-dev popt-dev libressl-dev soxr-dev avahi-dev libconfig-dev --update --no-cache
RUN cd /root \
  && git clone https://github.com/mikebrady/shairport-sync.git shairport-sync \
  && cd shairport-sync \
  && autoreconf -i -f \
  && ./configure \
        --with-alsa \
        --with-pipe \
        --with-stdout \
        --with-avahi \
        --with-ssl=openssl \
        --with-soxr \
        --with-metadata \
  && make \
  && make install \
  && cd /

# Install Shairport Runtime dependencies
RUN apk add dbus alsa-lib libdaemon popt libressl soxr avahi libconfig --update --no-cache

# Install snapcast
# Note: Do not install snapcast-server (does not include webdir, ...), install snapcast instead
RUN apk add snapcast --update --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community

# Install librespot (Spotify Client)
RUN apk add cargo --update --no-cache
RUN cargo install librespot

# Install NGINX for SSL reverse proxy to webinterface
RUN mkdir /run/nginx/
RUN apk add nginx --update --no-cache
COPY nginx.conf/default.conf /etc/nginx/http.d/default.conf

# Cleanup
RUN apk del --purge git build-base autoconf automake libtool alsa-lib-dev libdaemon-dev popt-dev libressl-dev soxr-dev avahi-dev libconfig-dev cargo \
  && apk cache clean
RUN rm -rf \
  /etc/ssl \
  /var/cache/apk/* \
  /lib/apk/db/* \
  /root/shairport-sync

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh


# Expose Ports
## Snapcast Ports
EXPOSE 1704-1705
EXPOSE 1780
## AirPlay ports
EXPOSE 3689/tcp
EXPOSE 5000-5005/tcp
EXPOSE 6000-6005/udp
## Avahi ports
EXPOSE 5353
## NGINX ports
EXPOSE 443 


# Run start script
ENV PATH "/root/.cargo/bin:$PATH"
CMD ["./start.sh"]
