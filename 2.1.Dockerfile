# bro
#
# VERSION               0.1

FROM debian:wheezy
MAINTAINER Justin Azoff <justin.azoff@gmail.com>

ENV WD /scratch

RUN mkdir ${WD}
WORKDIR /scratch

RUN dpkg -l | awk '{print $2}' | sort > old.txt

RUN apt-get update && apt-get -y upgrade && echo 2015-01-23
RUN apt-get -y install build-essential git bison flex gawk cmake swig libssl-dev libgeoip-dev libpcap-dev python-dev libcurl4-openssl-dev wget libncurses5-dev ca-certificates --no-install-recommends

# Bro < 2.3 needs libmagic and ./configure wants the file command
RUN apt-get -y install file libmagic-dev

# Build bro
ENV VER 2.1
RUN cd /tmp && wget http://www.bro.org/downloads/bro-${VER}.tar.gz --no-check-certificate
ADD ./common/buildbro ${WD}/common/buildbro
RUN ${WD}/common/buildbro ${VER} http://www.bro.org/downloads/bro-${VER}.tar.gz
RUN ln -s /usr/local/bro-${VER} /bro

# Final setup stuff

ADD ./common/getgeo.sh /usr/local/bin/getgeo.sh
RUN /usr/local/bin/getgeo.sh

ADD ./common/bro_profile.sh /etc/profile.d/bro.sh

# Cleanup, so docker-squash can do it's thing

RUN dpkg -l | awk '{print $2}' | sort > new.txt
RUN apt-get -y remove --purge $(comm -13 old.txt  new.txt|grep -- -dev)
RUN apt-get -y remove --purge $(comm -13 old.txt  new.txt|grep -v lib|grep -v ca-certificates|grep -v wget|grep -v curl|grep -v openssl)
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /scratch/*

env PATH /bro/bin/:$PATH

CMD /bin/bash -l
