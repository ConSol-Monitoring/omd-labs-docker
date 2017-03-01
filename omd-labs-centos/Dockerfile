FROM centos:7
MAINTAINER Simon Meggle<simon.meggle@consol.de>
EXPOSE 80 443 22 4730 5666

ENV REFRESHED 20161207

RUN rpm -Uvh "http://ftp.uni-stuttgart.de/epel/epel-release-latest-7.noarch.rpm" && \
    yum clean all && \
    yum -y update && \
    yum -y install which lsof vim git openssh-server tree

RUN rpm -Uvh "https://labs.consol.de/repo/testing/rhel7/x86_64/labs-consol-testing.rhel7.noarch.rpm" && \
    yum -y update && \
    yum -y install omd-labs-edition-daily

#### user environment
ENV HOME=/root
WORKDIR $HOME
ADD ./start.sh $HOME

#### ansible
ARG ANSIBLE_DROPIN=$HOME/ansible_dropin
ENV ANSIBLE_DROPIN=$ANSIBLE_DROPIN
ENV PYTHONPATH=/omd/versions/default/lib/python/
ENV ANSIBLE_CONFIG=${ANSIBLE_DROPIN}/ansible.cfg
ENV ANSIBLE_VERBOSITY=

# -- OMD site creation (DEMO)
ARG SITENAME=demo
ENV SITENAME=$SITENAME
RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
RUN omd create -u 1000 -g 1000 $SITENAME || true

# PERSISTENT VOLUMES
# Dynamic OMD data folders (etc, local, var) are renamed to .ORIG.
# On run time the start script (start.sh) will check if any of this folders is mounted from the host
# - if not => no data container mounts
#   -> remove symlinks
#   -> move .ORIG paths to the original location
# - if data container mount points
#   -> nothing to do, use the mounts.
RUN mv /omd/sites/$SITENAME/local /omd/sites/$SITENAME/local.ORIG && \
    mv /omd/sites/$SITENAME/etc /omd/sites/$SITENAME/etc.ORIG && \
    mv /omd/sites/$SITENAME/var /omd/sites/$SITENAME/var.ORIG

# -- ONBUILD
# when used as a base image, create another site if SITENAME was set to something else
#ONBUILD RUN [ "$SITENAME" != "demo" ] && echo "anderer als $SITENAME"
#ONBUILD RUN if [ "$SITENAME" == "demo" ]; then echo "gleich $SITENAME"; fi
#ONBUILD RUN if [ "$SITENAME" != "demo" ]; then echo "ungleich $SITENAME"; fi


#ONBUILD RUN if [ "$SITENAME" != "demo" ]; then omd create -u 1001 -g 1001 $SITENAME || true; fi
ONBUILD RUN [ "$SITENAME" != "demo" ] && omd create -u 1001 -g 1001 $SITENAME || true

ONBUILD RUN [ "$SITENAME" != "demo" ] && mv /omd/sites/$SITENAME/local /omd/sites/$SITENAME/local.ORIG && \
    mv /omd/sites/$SITENAME/etc /omd/sites/$SITENAME/etc.ORIG && \
    mv /omd/sites/$SITENAME/var /omd/sites/$SITENAME/var.ORIG || true

CMD ["./start.sh"]
