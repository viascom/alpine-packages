#!/bin/bash

mkdir -p packages/{aarch64,armhf,armv7,ppc64le,s390x,x86,x86_64}

lighttpd -D -f /etc/lighttpd/lighttpd.conf &
"$HOME"/api --username "$API_USERNAME" --password "$API_PASSWORD" --port "$API_PORT"
