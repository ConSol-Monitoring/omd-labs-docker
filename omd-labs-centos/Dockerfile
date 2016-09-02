FROM centos:7
MAINTAINER Simon Meggle<simon.meggle@consol.de>
EXPOSE 80 443 22 4730 5666

ENV REFRESHED 20160902

RUN rpm -Uvh "http://ftp.uni-stuttgart.de/epel/epel-release-latest-7.noarch.rpm" && \
    yum clean all && \
    yum -y update && \
    yum -y install which lsof vim git openssh-server tree

RUN rpm -Uvh "https://labs.consol.de/repo/testing/rhel7/x86_64/labs-consol-testing.rhel7.noarch.rpm" && \
    yum -y update && \
    yum -y install omd-labs-edition-daily

# OMD site creation
RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
RUN omd create demo || true
RUN omd config demo set APACHE_TCP_ADDR 0.0.0.0
RUN echo "root" | passwd --stdin root
RUN echo "demo" | passwd --stdin demo

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
