FROM perl:5.26.0

# Set the working directory to /build
WORKDIR /build

# Copy the current directory contents into the container at /oberth-prototype
ADD . /oberth-prototype

ENV PATH="/oberth-prototype/bin:${PATH}"
RUN /oberth-prototype/maint/replace-shebang /oberth-prototype/bin/oberthian

RUN oberthian bootstrap docker-install-apt
RUN oberthian bootstrap auto

CMD sh -c "cd /build/repository && oberthian && oberthian test"
