FROM perl:5.26.0

# Set the working directory to /build
WORKDIR /build

# Copy the current directory contents into the container at /build
ADD . /build

RUN apt-get update && xargs apt-get install -y --no-install-recommends < maint/docker-debian-packages

RUN perl ./bin/oberthian-bootstrap setup --dir extlib
RUN perl ./bin/oberthian-bootstrap generate-cpanfile --dir extlib
RUN perl ./bin/oberthian-bootstrap install-deps-from-cpanfile --dir extlib

RUN git clone https://github.com/project-renard/curie.git
RUN cd /build/curie && perl /build/bin/oberthian

# Run app.py when the container launches
CMD ["bash"]
