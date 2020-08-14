FROM perl:5.26

# Set the working directory to /build
WORKDIR /build

# Copy the current directory contents into the container at /launch-site
ADD . /launch-site

ENV PATH="/launch-site/vendor/p5-Orbital-Launch/bin:${PATH}"
RUN /launch-site/maint/replace-shebang /launch-site/vendor/p5-Orbital-Launch/bin/orbitalism

RUN orbitalism bootstrap docker-install-apt
RUN orbitalism bootstrap auto

CMD sh -c "cd /build/repository && orbitalism && orbitalism test"
