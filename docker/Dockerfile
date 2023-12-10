FROM golang:1.21.5-alpine AS builder
WORKDIR /app
COPY api/go.mod api/go.sum ./
RUN go mod download
COPY api/ .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o api .

FROM alpine:3.19.0

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

COPY .bashrc archive.sh start-services.sh $HOME/
RUN chown $USER:$GROUP $HOME/.bashrc; \
    chown $USER:$GROUP $HOME/archive.sh; \
    chmod +x $HOME/archive.sh; \
    chown $USER:$GROUP $HOME/start-services.sh; \
    chmod +x $HOME/start-services.sh

COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

COPY --from=builder /app/api $HOME/api
RUN chown $USER:$GROUP $HOME/api; \
    chmod +x $HOME/api

USER $USER
WORKDIR $HOME
SHELL ["/bin/bash", "-c"]

RUN set -eux; \
    mkdir -p packages/{aarch64,armhf,armv7,ppc64le,s390x,x86,x86_64}

CMD ["/usr/bin/dumb-init", "/home/exie/start-services.sh"]