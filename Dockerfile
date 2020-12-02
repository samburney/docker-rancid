FROM library/alpine:3.12.1

LABEL maintainer "Sam Burney <sburney@sifnt.net.au>"

# Environment variables for future use
ARG S6_OVERLAY_RELEASE=https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64.tar.gz
ENV S6_OVERLAY_RELEASE=${S6_OVERLAY_RELEASE}
ENV PACKAGES="busybox busybox-extras git rancid"
ENV UNTRUSTED_PACKAGES="openssh-client"

# Build OpenSSH from source in order to allow access to super old Cisco routers
ENV DEV_PACKAGES "abuild"
ADD /docker/openssh/ /
RUN cd /usr/src/openssh && \
    apk update && \
    apk add ${DEV_PACKAGES} && \
    abuild-keygen -a && \
    abuild -F -r && \
    apk del ${DEV_PACKAGES} && \
    rm -rf /usr/src/openssh /var/cache/distfiles && \
    { echo "/root/packages/src" ; cat /etc/apk/repositories ; } > /etc/apk/repositories.new && \
    mv -f /etc/apk/repositories.new /etc/apk/repositories

# Install packages
RUN apk update --allow-untrusted && \
    apk upgrade --no-cache && \
    apk add ${PACKAGES} && \
    apk add --allow-untrusted ${UNTRUSTED_PACKAGES} && \
    rm -rf /var/cache/apk/*

# Install s6-overlay
ADD ${S6_OVERLAY_RELEASE} /tmp/s6overlay.tar.gz
RUN tar xzf /tmp/s6overlay.tar.gz -C / \
    && rm /tmp/s6overlay.tar.gz

# Add any necessary files to filesystem
ADD /docker/root/ /

# Init
ENTRYPOINT [ "/init" ]
