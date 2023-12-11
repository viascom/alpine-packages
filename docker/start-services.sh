#!/bin/bash

mkdir -p packages/{aarch64,armhf,armv7,ppc64le,s390x,x86,x86_64}

lighttpd -D -f /etc/lighttpd/lighttpd.conf &
"$HOME"/api --username local-dev --password local-dev --port 8081
