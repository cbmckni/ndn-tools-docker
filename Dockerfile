# info and labels
FROM ubuntu:18.04
LABEL maintainer="Cole McKnight <cbmckni@clemson.edu>"
LABEL description="This docker image is a simple pre-built for conducting NDN-related experiments."

# package installation
# * update
# * basic applications / tools
# * all extra requirements for our installations
# * all apt repos to add
# * kubernetes
# * clone github repos
RUN apt-get -y -qq update \
 && apt-get -y -qq --no-install-recommends install git build-essential nano curl vim wget iperf3 traceroute iputils-ping \
 && apt-get -y -qq --no-install-recommends install ca-certificates gnupg2 \
 && DEBIAN_FRONTEND="noninteractive" apt-get -y -qq --no-install-recommends install tzdata \
 && apt-get -y -qq --no-install-recommends install -y g++ pkg-config python3-minimal libboost-all-dev libssl-dev \
 && apt-get -y -qq --no-install-recommends install libsqlite3-dev software-properties-common libpcap-dev libsystemd-dev \
 && add-apt-repository ppa:named-data/ppa \
 && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
 && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
 && apt-get -y -qq update \
 && apt-get -y -qq --no-install-recommends install kubectl \
 && git clone https://github.com/named-data/ndn-cxx.git \
 && git clone --recursive https://github.com/named-data/NFD.git \
 && git clone https://github.com/named-data/ndn-tools.git \
 && rm -rf /var/lib/apt/lists/*

# install ndn-cxx
WORKDIR ndn-cxx
RUN CXXFLAGS="-O1 -g3" ./waf configure --debug --with-tests && ./waf && ./waf install && ldconfig
WORKDIR ..

# install nfd
WORKDIR NFD
RUN ./waf configure && ./waf && ./waf install
WORKDIR ..

# install ndn-tools
WORKDIR ndn-tools
RUN ./waf configure && ./waf && ./waf install
WORKDIR ..

# initial configuration and setup
RUN cp /usr/local/etc/ndn/nfd.conf.sample /usr/local/etc/ndn/nfd.conf \
    && ndnsec-keygen /`whoami` | ndnsec-install-cert - \
    && mkdir -p /usr/local/etc/ndn/keys \
    && ndnsec-cert-dump -i /`whoami` > default.ndncert \
    && mv default.ndncert /usr/local/etc/ndn/keys/default.ndncert \
    && mkdir -p /share /logs
EXPOSE 6363/tcp
EXPOSE 6363/udp
ENV CONFIG=/usr/local/etc/ndn/nfd.conf
ENV LOG_FILE=/logs/nfd.log

# entrypoint
RUN mkdir -p /workspace
WORKDIR /workspace
ENTRYPOINT /usr/local/bin/nfd -c $CONFIG > $LOG_FILE 2>&1 & /bin/bash
