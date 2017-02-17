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

### Use data containers

#### Generate data folders

As soon as the container dies, all monitoring data (configuration files, RRD data, InfluxDB, log files etc.) are lost, too.
To store variable data of OMD (`etc, local, var` in `$OMD_ROOT`) into a host-mounted volume, you must first extract the data out of the container:  

Start the container manually with three host-mounted volumes (the folder `site` and its ubfolders will be created automatically):

      make bashvol

This will start a shell in the container. Check that the folders are mounted correctly:

      [root@3d98c2a9691e ~]# mount | grep omd
      osxfs on /opt/omd/sites/demo/local type fuse.osxfs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576)
      osxfs on /opt/omd/sites/demo/etc type fuse.osxfs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576)
      osxfs on /opt/omd/sites/demo/var type fuse.osxfs (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other,max_read=1048576)   

Change to the site user (default: demo). You will see that there is a `.ORIG` folder for each data directory. These folders were renamed directly after the site creation to allow mounting external data (`etc, local, var`) to the original name (reason: symlinks are *not* allowed here!).

(The "start.sh" script will rename all `.ORIG` folders to the original name in case there are no mounted volumes. All this is done *before* the OMD site startup.)

      [root@3d98c2a9691e ~]# su - demo
      OMD[demo]:~$ ls -la  | grep -E "(etc|local|var)"
      drwxr-xr-x  2 root root   68 Feb 17 07:41 etc/
      drwxr-xr-x 47 demo demo 4096 Feb 17  2017 etc.ORIG/
      drwxr-xr-x  2 root root   68 Feb 17 07:41 local/
      drwxr-xr-x  8 demo demo 4096 Feb 17  2017 local.ORIG/
      drwxr-xr-x  2 root root   68 Feb 17 07:41 var/
      drwxr-xr-x 19 demo demo 4096 Feb 10 09:23 var.ORIG/

Now rsync all files of the `.ORIG` folders into the mounted volumes:

      OMD[demo]:~$ for d in etc var "local"; do rsync -av "$d.ORIG/" "$d"; done

Exit the container. You should see a new folder `site` within the project, containing the three folders `etc, local` and `var`.

#### Start OMD-Labs with data volumes

To test if everything worked, simply start the container with

      make startvol

This starts the container with the three data volumes. Everything the container writes into one of those three folder, it will write it into the persistent file system.   

(`make startvol` is just a handy shortcut to bring up the container. In Kubernetes/OpenShift you won't need this.)  

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
