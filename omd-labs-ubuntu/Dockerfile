FROM ubuntu:latest
MAINTAINER Simon Meggle<simon.meggle@consol.de>
EXPOSE 80 22 4730 5666

ENV REFRESHED 20160229

RUN  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf; \ 
    echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \ 
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \ 
    cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

RUN gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7 && \
    gpg --armor --export F8C1CA08A57B9ED7 | apt-key add - && \
    echo "deb http://labs.consol.de/repo/testing/ubuntu $(lsb_release -sc) main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y lsof vim git openssh-server tree tcpdump libevent-2.0-5 omd-labs-edition-daily

RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
RUN omd create demo || true
RUN omd config demo set APACHE_TCP_ADDR 0.0.0.0
RUN echo 'root:root' | chpasswd
RUN echo 'demo:demo' | chpasswd

ENV OMD_DEMO /opt/omd/sites/demo

ADD run_omd.sh /run_omd.sh
CMD ["/run_omd.sh"]
