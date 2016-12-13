# omd-labs-docker

OMD Labs Nightly (https://labs.consol.de/de/omd/index.html) on Docker with Ansible support.

Author: Simon Meggle, *simon.meggle at consol.de*

## Automated builds

Each image build gets triggered by the OMD Labs build system as soon as there are new packages available:

* https://hub.docker.com/r/consol/omd-labs-centos/
* https://hub.docker.com/r/consol/omd-labs-debian/
* https://hub.docker.com/r/consol/omd-labs-ubuntu/

## Usage

Run a bare installation of OMD Labs Edition:

    # Centos 7
    docker run -p 8443:443 consol/omd-labs-centos
    # Ubuntu 16.04
    docker run -p 8443:443 consol/omd-labs-ubuntu
    # Debian 8
    docker run -p 8443:443 consol/omd-labs-debian

Alternatively, you can use the Makefile for common operations:

    # same as 'docker run' above
    make start
    # build a "local/" image without overwriting the consol/ image
    make build
    # start just the bash
    make bash

## Ansible drop-ins
### Image, image, image, ...
So, you want to test something specific in OMD and configure the site to your needs? Normally you would create a Dockerfile using the OMD labs orginal image (``FROM: ...``), and write an more or less clean Shell script for the ``CMD/ENTRYPOINT`` to install software and do the configuration stuff. Of course, you will get a new image - all because of a handful of changes.

### Image, Ansible, Ansible, Ansible...

#### Startup order
For some time OMD-Labs comes with **full Ansible support**, which we can use to modify the container instance *on startup*. **How does this work?**

By default, the OMD-labs containers start with the CMD `/root/start.sh`. This script

* checks if there are any files in `/root/ansible_omd/dropin_role`. If so, it starts it by calling the playbook `/root/ansible_omd/playbook.yml`.
* starts the OMD site "demo"
* starts Apache as a foreground process to let the container stay alive

##### Include own drop-in roles

To use your own drop-in role, just **mount a Ansible role folder** on the host to the drop-in folder within the container:

    docker run -it -p 8443:443 -v path/to/ansible/role/on/host:/root/ansible/dropin_role consol/omd-labs-debian

#### Debugging

If you want to see more verbose output from Ansible to debug your role, add the environment variable `ANSIBLE_VERBOSITY`:

    docker run -it -p 8443:443 -e ANSIBLE_VERBOSITY="-vv" -v path/to/ansible/role/on/host:/root/ansible/dropin_role consol/omd-labs-debian
