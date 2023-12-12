#!/usr/bin/env bash

echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

wget -P /etc/apk/keys https://cdn.azul.com/public_keys/alpine-signing@azul.com-5d5dc44c.rsa.pub
echo "https://repos.azul.com/zulu/alpine" >> /etc/apk/repositories;
