FROM debian:8
MAINTAINER Simon Meggle<simon.meggle@consol.de>
EXPOSE 80 443 22 4730 5666

ENV REFRESHED 20161207
ARG SITENAME=demo


ENV DEBIAN_FRONTEND noninteractive

RUN  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf; \
    echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \
    cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

RUN apt-get update && \
    apt-get install -y lsof vim git openssh-server tree tcpdump libevent-2.0-5

RUN gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7 && gpg --armor --export F8C1CA08A57B9ED7 | apt-key add - && \
    echo "deb http://labs.consol.de/repo/testing/debian $(cat /etc/os-release  | grep 'VERSION=' | tr '(' ')' | cut -d ')' -f2) main" > /etc/apt/sources.list.d/labs-consol-testing.list && \
    apt-get update && \
    apt-get install -y omd-labs-edition-daily && \
    apt-get clean

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# -- OMD site creation
RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
RUN omd create $SITENAME || true
RUN omd config $SITENAME set APACHE_TCP_ADDR 0.0.0.0
RUN echo 'root:root' | chpasswd
RUN echo "$SITENAME:$SITENAME" | chpasswd
ENV OMD_DEMO /opt/omd/sites/$SITENAME

# -- prepare OMD start by Ansible
COPY ansible_omd /root/ansible_omd
ENV PYTHONPATH=/omd/versions/default/lib/python/
ENV ANSIBLE_CONFIG=/root/ansible_omd/ansible.cfg
# dropin-role dir must be mounted as volume into /root/ansible_omd (=playbook_dir)
# e.g. -v $(pwd)/somewhere/on/host:/root/ansible_omd/dropin_role
ENV ANSIBLE_DROPIN_ROLE=dropin_role
ENV ANSIBLE_VERBOSITY=

WORKDIR /root
ADD start.sh /root/
CMD /root/start.sh
