# docker-omd-labs

Run OMD Labs (https://labs.consol.de/de/omd/index.html) on Docker with Ansible support.

## Usage

Run a bare installation of OMD Labs Edition: 

    # centos 7
    docker run -p 8443:443 consol/omd-labs-centos
    # Ubuntu 14.04
    docker run -p 8443:443 consol/omd-labs-ubuntu
    # Debian 8
    docker run -p 8443:443 consol/omd-labs-debian

## Ansible drop-ins
### Image, image, image, ... 
So, you want to test something specific in OMD and configure the site to your needs? Normally you would create a Dockerfile using the OMD labs orginal image (``FROM: ...``), and write an more or less clean Shell script for the ``CMD/ENTRYPOINT`` to install software and do the configuration stuff. Of course, you will get a new image - all because of a handful of changes. 

### Image, Ansible, Ansible, Ansible... 

For some time OMD comes with **full Ansible support**, which we can use to modify the container instance *on startup*. **How does this work?**

The Dockerfiles of each image define an Ansible playbook run as ``CMD``: 
 
    CMD /omd/sites/demo/bin/ansible-playbook -i localhost, ansible/playbook.yml -c local -e ANSIBLE_DROPIN_ROLE=$ANSIBLE_DROPIN_ROLE $ANSIBLE_VERBOSITY

The ``-i localhost,`` (watch the comma) looks weird, but allows us to execute the playbook on the local host without defining an inventory. ``-c local`` avoids needless SSH to localhost.

``ANSIBLE_DROPIN_ROLE`` is a variable defined few lines before and points to a role directory within the ansible playbook folder. It is empty by default and so Ansible will skip this task if you are starting the container as shown in "Usage". 


Instead of baking and deleting images as described above you now can **mount a drop-in custom Ansible role**, which is executed first at the container startup: 

    docker run -it -p 8443:443 -v ~/path/to/ansible/role/on/host:/root/ansible/dropin_role consol/omd-labs-debian

If you want to see more output from Ansible to debug the role: 

    docker run -it -p 8443:443 -e ANSIBLE_VERBOSITY="-vv" -v ~/path/to/ansible/role/on/host:/root/ansible/dropin_role consol/omd-labs-debian


Have a look at the [**Sakuli project**](https://github.com/Consol/sakuli) OMD-drop-in rule, which

* creates examples Nagios objects (hosts/services/commands)
* installs the graph template
* configures mod-gearman to receive Sakuli events

   
