# omd-labs-docker

OMD Labs Nightly (https://labs.consol.de/de/omd/index.html) on Docker with Ansible support.

Author: Simon Meggle, *simon.meggle at consol.de*

## Automated builds

Each image build gets triggered by the OMD Labs build system as soon as there are new packages of OMD available:

* https://hub.docker.com/r/consol/omd-labs-centos/
* https://hub.docker.com/r/consol/omd-labs-debian/
* https://hub.docker.com/r/consol/omd-labs-ubuntu/

The image already contains a "demo" site.

## Usage

### run the "demo" site

Run the "demo" site in OMD Labs Edition:

    # Centos 7
    docker run -p 8443:443 consol/omd-labs-centos
    # Ubuntu 16.04
    docker run -p 8443:443 consol/omd-labs-ubuntu
    # Debian 8
    docker run -p 8443:443 consol/omd-labs-debian

Use the Makefile to work with *locally built* images:

    # run a local image
    make start
    # build a "local/" image without overwriting the consol/ image
    make build
    # start just the bash
    make bash

### run a custom site

If you want to create a custom site, you have to build an own image:

* clone this repository, `cd` into the folder containg the Dockerfile, e.g. `omd-labs-centos`
* build a local image:
      SITENAME=mynewsite
      make build    
* run the image:
      docker run -p 8443:443 local/omd-labs-centos

## Ansible drop-ins

For some time OMD-Labs comes with **full Ansible support**, which we can use to modify the container instance *on startup*. **How does this work?**

### start sequence
By default, the OMD-labs containers start with the CMD `/root/start.sh`. This script

* checks if there is a `playbook.yml` in `$ANSIBLE_DROPIN` (default: `/root/ansible_dropin`, changeable by environemt). If found, the playbook is executed. It is completely up to you if you only place one single task in `playbook.yml`, or if you also include Ansible roles. (with a certain point of complexity, you should think about a separate image, though...)
* starts the OMD site "demo" & Apache as a foreground process

### Include Ansible drop-ins

Just a folder containing a valid playbook into the container:

    docker run -it -p 8443:443 -v $(pwd)/my_ansible_dropin:/root/ansible_drop consol/omd-labs-debian

### Debugging

If you want to see more verbose output from Ansible to debug your role, add the environment variable `ANSIBLE_VERBOSITY`:

    docker run -it -p 8443:443 -e ANSIBLE_VERBOSITY="-vv" -v $(pwd)/my_ansible_dropin:/root/ansible_drop consol/omd-labs-debian
