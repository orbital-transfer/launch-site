# launch-site

Requires a local X11 server.

To build and run the Docker image:

```sh
git clone --recurse-submodules https://github.com/orbital-transfer/launch-site.git \
    && cd launch-site \
    && ./maint/build-docker \
    && ./maint/dev-orbital
```
