FROM lsiobase/alpine:3.12

LABEL maintainer "Sam Burney <sburney@sifnt.net.au>"

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

# Environment variables for future use
ENV PACKAGES="busybox busybox-extras git rancid msmtp"
ENV UNTRUSTED_PACKAGES="openssh-client"

# Install packages
RUN apk update --allow-untrusted && \
    apk upgrade --no-cache && \
    apk add ${PACKAGES} && \
    apk add --allow-untrusted ${UNTRUSTED_PACKAGES} && \
    rm -rf /var/cache/apk/*

# Add sendmail command
RUN ln -sf /usr/bin/msmtp /usr/sbin/sendmail && \
    chmod u+s /usr/bin/msmtp

# Add Vyattta/VyOS support
RUN git clone https://github.com/jontow/rancid-vyos.git /tmp/rancid-vyos && \
    cp /tmp/rancid-vyos/vlogin /usr/bin/ && \
    cp /tmp/rancid-vyos/vyos.pm /usr/lib/rancid/ && \
    cat /tmp/rancid-vyos/rancid.types.conf >> /etc/rancid/rancid.types.conf && \
    echo "#" >> /etc/rancid/rancid.types.conf && \
    rm -rf /tmp/rancid-vyos

# Add any necessary files to filesystem
ADD /docker/root/ /

# Init
ENTRYPOINT [ "/init" ]
