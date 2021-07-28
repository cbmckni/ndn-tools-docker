FROM ubuntu:18.04
LABEL maintainer="Cole McKnight <cbmckni@clemson.edu>"
LABEL description="This docker image is a simple pre-built for conducting NDN-related experiments on a kubernetes cluster."

RUN apt-get -y -qq update \
 && apt-get -y -qq --no-install-recommends install git build-essential nano curl vim wget iperf3 traceroute iputils-ping ca-certificates gnupg2 \
 && echo "deb [trusted=yes] https://nfd-nightly-apt.ndn.today/ubuntu bionic main" | tee /etc/apt/sources.list.d/nfd-nightly.list \
 && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
 && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
 && apt-get -y -qq update \
 && apt-get -y -qq --no-install-recommends install -f kubectl libndn-cxx-dev nfd ndnchunks ndnsec ndnping ndnpeek \
 && rm -rf /var/lib/apt/lists/* \
 && cp /etc/ndn/nfd.conf.sample /etc/ndn/nfd.conf \
 && ndnsec-keygen /`whoami` | ndnsec-install-cert - \
 && mkdir -p /etc/ndn/keys /share /logs /workspace \
 && ndnsec-cert-dump -i /`whoami` > default.ndncert \
 && mv default.ndncert /etc/ndn/keys/default.ndncert \
 && setcap -r /usr/bin/nfd || true

EXPOSE 6363/tcp
EXPOSE 6363/udp
ENV CONFIG=/etc/ndn/nfd.conf
ENV LOG_FILE=/logs/nfd.log
WORKDIR /workspace
ENTRYPOINT /usr/bin/nfd -c $CONFIG > $LOG_FILE 2>&1 & /bin/bash
