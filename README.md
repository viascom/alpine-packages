# alpine-packages

Private Alpine Package Manager.

# Getting Started

```bash
docker run \
  --name alpine-packages \
  --publish 29535:8080 \
  --mount type=bind,source=YOUR_SECRET_KEY,target=/home/exie/.abuild/YOUR_SECRET_KEY.rsa,readonly \
  --mount type=bind,source=YOUR_PUBLIC_KEY,target=/home/exie/.abuild/YOUR_PUBLIC_KEY.rsa,readonly \
  --detach \
  viascom/alpine-packages:latest
```
