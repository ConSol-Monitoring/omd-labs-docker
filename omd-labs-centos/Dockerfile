FROM centos:7
MAINTAINER Simon Meggle<simon.meggle@consol.de>
EXPOSE 80 443 22 4730 5666

ENV REFRESHED 20161207
ARG SITENAME=demo


RUN rpm -Uvh "http://ftp.uni-stuttgart.de/epel/epel-release-latest-7.noarch.rpm" && \
    yum clean all && \
    yum -y update && \
    yum -y install which lsof vim git openssh-server tree

RUN rpm -Uvh "https://labs.consol.de/repo/testing/rhel7/x86_64/labs-consol-testing.rhel7.noarch.rpm" && \
    yum -y update && \
    yum -y install omd-labs-edition-daily









# -- OMD site creation
RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
RUN omd create $SITENAME || true
RUN omd config $SITENAME set APACHE_TCP_ADDR 0.0.0.0
RUN echo "root" | passwd --stdin root
RUN echo "$SITENAME" | passwd --stdin $SITENAME
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
CMD /root/start.sh $SITENAME
