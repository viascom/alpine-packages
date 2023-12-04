FROM alpine:3.18.5

ENV USER=exie \
    GROUP=party \
    CUSTOM_UID=1001 \
    TZ=UTC \
    LANG=en_US.utf8

ENV LANGUAGE=$LANG \
    HOME=/home/$USER

COPY packages.list /tmp

RUN set -eux; \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories > /dev/null; \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories > /dev/null; \
    apk -U upgrade; \
    apk -v add util-linux alpine-conf; \
    xargs -r apk -v add < /tmp/packages.list; \
    addgroup --system --gid $CUSTOM_UID $GROUP; \
    adduser --system --disabled-password --uid $CUSTOM_UID $USER -G $GROUP -s /bin/bash; \
    setup-timezone -z $TZ; \
    apk del util-linux alpine-conf; \
    rm -rf /var/cache/apk/*; \
    rm -rf /tmp/*

COPY .bashrc archive.sh $HOME
RUN chown -R $USER:$GROUP $HOME/.bashrc; \
    chown -R $USER:$GROUP $HOME/archive.sh; \
    chmod +x $HOME/archive.sh

COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

USER $USER
WORKDIR $HOME
SHELL ["/bin/bash", "-c"]

RUN set -eux; \
    mkdir -p packages/{aarch64,armhf,armv7,ppc64le,s390x,x86,x86_64}

CMD ["/usr/bin/dumb-init", "lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]