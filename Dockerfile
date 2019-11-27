FROM perl:5.26

# Set the working directory to /build
WORKDIR /build

# Copy the current directory contents into the container at /oberth-prototype
ADD . /oberth-prototype

ENV PATH="/oberth-prototype/vendor/p5-Oberth-Launch/bin:${PATH}"
RUN /oberth-prototype/maint/replace-shebang /oberth-prototype/vendor/p5-Oberth-Launch/bin/oberthian

RUN oberthian bootstrap docker-install-apt
RUN oberthian bootstrap auto

CMD sh -c "cd /build/repository && oberthian && oberthian test"
