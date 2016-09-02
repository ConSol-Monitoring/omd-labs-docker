FROM ubuntu:14.04
MAINTAINER Simon Meggle<simon.meggle@consol.de>
EXPOSE 80 443 22 4730 5666

ENV REFRESHED 20160822

ENV DEBIAN_FRONTEND noninteractive

RUN  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf; \
    echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \
    cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

RUN apt-get update && \
    apt-get install -y lsof vim git openssh-server tree tcpdump libevent-2.0-5 

RUN gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7 && gpg --armor --export F8C1CA08A57B9ED7 | apt-key add - && \
    echo "deb http://labs.consol.de/repo/testing/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d'=' -f2) main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y omd-labs-edition-daily &&  \
    apt-get clean

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# OMD site creation
RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
RUN omd create demo || true
RUN omd config demo set APACHE_TCP_ADDR 0.0.0.0
RUN echo 'root:root' | chpasswd
RUN echo 'demo:demo' | chpasswd

ENV OMD_DEMO /opt/omd/sites/demo
ENV PYTHONPATH=/omd/sites/demo/lib/python:/omd/sites/demo/local/lib/python
ENV ANSIBLE_CONFIG=/root/ansible/ansible.cfg
# dropin-role dir must be mounted as volume into /root/ansible (=playbook_dir)
# e.g. -v $(pwd)/somewhere/on/host:/root/ansible/dropin_role
ENV ANSIBLE_DROPIN_ROLE=dropin_role
ENV ANSIBLE_VERBOSITY=

COPY ansible /root/ansible

WORKDIR /root
CMD /omd/sites/demo/bin/ansible-playbook -i localhost, ansible/playbook.yml -c local -e ANSIBLE_DROPIN_ROLE=$ANSIBLE_DROPIN_ROLE $ANSIBLE_VERBOSITY
