FROM golang:1.22.1-alpine AS builder
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
    LANG=en_US.utf8 \
    API_USERNAME=local-dev \
    API_PASSWORD=local-dev \
    API_PORT=8081

ENV LANGUAGE=$LANG \
    HOME=/home/$USER

COPY packages.list configure-repositories.sh /tmp/

RUN set -eux; \
    chmod +x /tmp/configure-repositories.sh; \
    sh /tmp/configure-repositories.sh; \
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
    chmod +x $HOME/start-services.sh; \
    mkdir -p /var/log/alpine-packages/; \
    chown -R $USER:$GROUP /var/log/alpine-packages/

COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

COPY --from=builder /app/api $HOME/api
RUN chown $USER:$GROUP $HOME/api; \
    chmod +x $HOME/api

USER $USER
WORKDIR $HOME
SHELL ["/bin/bash", "-c"]
CMD ["/usr/bin/dumb-init", "/home/exie/start-services.sh"]