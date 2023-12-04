#!/bin/bash

lighttpd -D -f /etc/lighttpd/lighttpd.conf &
"$HOME"/api --username local-dev --password local-dev --port 8081
