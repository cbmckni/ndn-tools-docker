# info
FROM ubuntu
LABEL maintainer "Cole McKnight <cbmckni@clemson.edu>"

# update, base packages, requirements
RUN apt-get update  &&  apt-get install -y \
         git build-essential nano curl vim wget iperf3 traceroute iputils-ping \
         g++ pkg-config python3-minimal libboost-all-dev libssl-dev libsqlite3-dev software-properties-common libpcap-dev libsystemd-dev
# sub install - tzdata
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

# kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
	&& echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
	&& apt-get update -qq \
	&& apt-get install -qq -y kubectl

# install ndn-cxx
RUN git clone https://github.com/named-data/ndn-cxx.git
WORKDIR ndn-cxx
RUN CXXFLAGS="-O1 -g3" ./waf configure --debug --with-tests
RUN ./waf
RUN ./waf install
WORKDIR ..

# install nfd
RUN add-apt-repository ppa:named-data/ppa
RUN apt update
RUN git clone --recursive https://github.com/named-data/NFD.git
WORKDIR NFD
RUN ./waf configure
RUN ./waf
RUN ./waf install
WORKDIR ..

# install ndn-tools
RUN git clone https://github.com/named-data/ndn-tools.git
WORKDIR ndn-tools
RUN ./waf configure
RUN ./waf
RUN ./waf install
WORKDIR ..

# initial configuration
RUN cp /usr/local/etc/ndn/nfd.conf.sample /usr/local/etc/ndn/nfd.conf \
    && ndnsec-keygen /`whoami` | ndnsec-install-cert - \
    && mkdir -p /usr/local/etc/ndn/keys \
    && ndnsec-cert-dump -i /`whoami` > default.ndncert \
    && mv default.ndncert /usr/local/etc/ndn/keys/default.ndncert

RUN mkdir /share \
    && mkdir /logs

# cleanup
RUN apt autoremove \
    && apt-get remove -y git build-essential python pkg-config

EXPOSE 6363/tcp
EXPOSE 6363/udp

ENV CONFIG=/usr/local/etc/ndn/nfd.conf
RUN mkdir -p /logs
ENV LOG_FILE=/logs/nfd.log

# Entrypoint
RUN mkdir -p /workspace
WORKDIR /workspace
ENTRYPOINT /usr/local/bin/nfd -c $CONFIG > $LOG_FILE 2>&1 & /bin/bash
