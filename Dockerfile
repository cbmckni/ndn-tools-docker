FROM ubuntu
LABEL maintainer "Cole McKnight <cbmckni@clemson.edu>"
ARG VERSION_CXX=master
ARG VERSION_NFD=master

# install tools
RUN  apt-get update \
     && apt-get install -y git build-essential

# install ndn-cxx and NFD dependencies
RUN apt install -y g++ pkg-config python3-minimal libboost-all-dev libssl-dev libsqlite3-dev 

RUN git clone https://github.com/named-data/ndn-cxx.git 
WORKDIR ndn-cxx
RUN ./waf configure  # on CentOS, add --without-pch
RUN ./waf
RUN ./waf install
WORKDIR ..

# install NFD
RUN apt -y install libpcap-dev

RUN git clone https://github.com/named-data/NFD.git 
WORKDIR NFD
RUN ./waf configure --without-websocket 
RUN ./waf
RUN ./waf install
WORKDIR ..

# install ndn-tools 
RUN git clone https://github.com/susmit85/ndn-tools.git
WORKDIR ndn-tools
RUN ./waf configure
RUN ./waf
RUN ./waf install
WORKDIR ..
