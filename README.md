# omd-labs-docker

OMD "Labs" Edition (https://omd.consol.de/docs/omd/) on Docker with Ansible support.

Author: Sven Nierlein, *sven.nierlein at consol.de*

Original Author: Simon Meggle

- https://omd.consol.de/docs/omd/
- https://github.com/ConSol-Monitoring/omd-labs-docker

## Automated builds, branches & tags

Each image build gets triggered by the OMD Labs build system as soon as there are new packages of OMD available:

* https://hub.docker.com/r/consol/omd-labs-rocky/  (x86 / arm64)
* https://hub.docker.com/r/consol/omd-labs-debian/ (x86 / arm64)

Automated builds are triggered for the following branches:

* *master* => **:nightly** (=snapshot builds)
* *vX.XX*  => **:vX.XX**   (=stable version)
* *latest* => **:latest**  (=latest stable version)

Each image already contains a "demo" site.

## Usage

### run the "demo" site

Run the "demo" site in OMD Labs Edition:

    # Rocky 9
    docker run -p 8443:443 consol/omd-labs-rocky
    # Debian 13
    docker run -p 8443:443 consol/omd-labs-debian

Use the Makefile to work with *locally built* images:

    # run a local image
    make -f Makefile.omd-labs-rocky start
    # build a "local/" image without overwriting the consol/ image
    make -f Makefile.omd-labs-rocky build
    # start just the bash
    make -f Makefile.omd-labs-rocky bash

The container will log its startup process:

```
Config and start OMD site: demo
--------------------------------------
Checking for volume mounts...
--------------------------------------
 * local/: [No Volume]
 * etc/: [No Volume]
 * var/: [No Volume]


Checking for Ansible drop-in...
--------------------------------------
Nothing to do (/root/ansible_dropin/playbook.yml not found).

omd-labs: Starting site demo...
--------------------------------------
Preparing tmp directory /omd/sites/demo/tmp...Starting rrdcached...OK
Starting npcd...OK
Starting naemon...OK
Starting dedicated Apache for site demo...OK
Initializing Crontab...OK
OK
```

Notice the section "Data volume check". In this case there were no host mounted data volumes used. The "start.sh" script has renamed all `.ORIG` folders to the original name in case there are no mounted volumes.

### Custom sites

#### Change the default sitename
The *default sitename* "demo" can be changed. Build a custom image while `SITENAME` is set:

* clone this repository, `cd` into the folder containg the Dockerfile, e.g. `omd-labs-rocky`
* build a local image:
```
export SITENAME=mynewsite; make -f Makefile.omd-labs-rocky build
```

Each container instance of this image will start the site "mynewsite" instead of "demo".

#### Add another site dynamically

If you need to set the *sitename dynamically* without building the whole image from scratch (see above), you can create images with another OMD-site beneath the default site (see above). Create a custom `Dockerfile` which uses the original image as the base image:

```
FROM: consol/omd-labs-rocky:nightly
...
...
```

The sitename in your custom OMD image can now be changed by setting the variable `NEW_SITENAME` to a new value:

```
export NEW_SITENAME=anothersite
```

The ONBUILD commands in the original Dockerfile execute after the current Dockerfile build completes. ONBUILD executes in any child image derived FROM the current image. Think of the ONBUILD command as an instruction the parent Dockerfile gives to the child Dockerfile.

### Use data containers

#### Host mounted data folders

As soon as the container dies, all monitoring data (configuration files, RRD data, InfluxDB, log files etc.) are lost, too. To keep the data persistent, use host mounted volumes.

This command

      make -f Makefile.omd-labs-rocky startvol

starts the container with three volume mounts:

* `./site/etc`   => `$OMD_ROOT/etc.mount`
* `./site/local` => `$OMD_ROOT/local.mount`
* `./site/var`   => `$OMD_ROOT/var.mount`

On the very first start, this folders will be created on the host file system.
In that case, the `start.sh` synchronize ongoing through `lsycnd` the content into the volumes (`etc.mount`, `local.mount`, `var.mount`) from the original folders (`etc`, `local`, `var`):

* `$OMD_ROOT/etc`   => `$OMD_ROOT/etc.mount`
* `$OMD_ROOT/local` => `$OMD_ROOT/local.mount`
* `$OMD_ROOT/var`   => `$OMD_ROOT/var.mount`


```
Config and start OMD site: demo
--------------------------------------
Checking for volume mounts...
--------------------------------------
 * local/: [EXTERNAL Volume] at /opt/omd/sites/demo/local.mount
   * mounted volume is writable
   => local.mount is empty; initial sync from local local ...
   * writing the lsyncd config for local.mount...
 * etc/: [EXTERNAL Volume] at /opt/omd/sites/demo/etc.mount
   * mounted volume is writable
   => etc.mount is empty; initial sync from local etc ...
   * writing the lsyncd config for etc.mount...
 * var/: [EXTERNAL Volume] at /opt/omd/sites/demo/var.mount
   * mounted volume is writable
   => var.mount is empty; initial sync from local var ...
   * writing the lsyncd config for var.mount...

lsyncd: Starting lsyncd ...
--------------------------------------
16:38:44 Normal: --- Startup, daemonizing ---
16:38:44 Normal: --- Startup, daemonizing ---

Checking for Ansible drop-in...
--------------------------------------
Nothing to do (/root/ansible_dropin/playbook.yml not found).

omd-labs: Starting site demo...
--------------------------------------
Preparing tmp directory /omd/sites/demo/tmp...Starting rrdcached...OK
Starting npcd...OK
Starting naemon...OK
Starting dedicated Apache for site demo...OK
Initializing Crontab...OK
OK
```

On the next start the folders are *not* empty anymore and used as usual.

#### Checking available space on mount point

Before OMD starts, each of the three mount points (etc, local, var) can be checked for free available disk space to ensure that the container can store its data. The threshold can be given as an environent variable in the `docker run` command. If there is not enough space on any mount point, the startup script fails. On a container orchestration platform like OpenShift this should be handled by your deployment config (=the running pod only gets shutdown if the new pod was started properly).   

```
docker run -d -p 8443:443 \
  -v $(pwd)/site/local:/omd/sites/demo/local.mount \
  -v $(pwd)/site/etc:/omd/sites/demo/etc.mount     \
  -v $(pwd)/site/var:/omd/sites/demo/var.mount     \     
  -e VOL_VAR_MB_MIN=700000  \
  -e VOL_ETC_MB_MIN=500     \
  -e VOL_LOCAL_MB_MIN=6000  \
  consol/omd-labs-rocky:nightly

docker logs 91992828cc1dca7839cb2842933897b94329fe2c6b395c5ccb8b9fa056057679
Config and start OMD site: demo
--------------------------------------
Checking for volume mounts...
--------------------------------------
 * local/: [EXTERNAL Volume] at /opt/omd/sites/demo/local.mount
   * OK: Free space on /opt/omd/sites/demo/local.mount is 499826MB (required: 6000MB)
   * OK: mounted volume is writable
   <= Volume contains data; sync into local local ...
   * writing the lsyncd config for local.mount...
 * etc/: [EXTERNAL Volume] at /opt/omd/sites/demo/etc.mount
   * OK: Free space on /opt/omd/sites/demo/etc.mount is 499825MB (required: 500MB)
   * OK: mounted volume is writable
   <= Volume contains data; sync into local etc ...
   * writing the lsyncd config for etc.mount...
 * var/: [EXTERNAL Volume] at /opt/omd/sites/demo/var.mount
   * ERROR: Mounted volume has only 499825MB left (required: 700000MB, set by VOL_VAR_MB_MIN).
no crontab for demo
Removing Crontab...Stopping Nagflux.... Not running.
Stopping dedicated Apache for site demo...(not running)...OK
Stopping naemon...not running...OK
Stopping Grafana.... Not running.
Stopping influxdb.... Not running.
```


#### Start OMD-Labs with data volumes

To test if everything worked, simply start the container with

      make startvol

This starts the container with the three data volumes. Everything the container writes into one of those three folder, it will synchronized into the persistent file system.   

(`make startvol` is just a handy shortcut to bring up the container. In Kubernetes/OpenShift you won't need this.)  

## Ansible drop-ins

For some time OMD-Labs comes with **full Ansible support**, which we can use to modify the container instance *on startup*. **How does this work?**

### start sequence
By default, the OMD-labs containers start with the CMD `/root/start.sh`. This script

* checks if there is a `playbook.yml` in `$ANSIBLE_DROPIN` (default: `/root/ansible_dropin`, changeable by environment). If found, the playbook is executed. It is completely up to you if you only place one single task in `playbook.yml`, or if you also include Ansible roles. (with a certain point of complexity, you should think about a separate image, though...)
* starts the OMD site "demo" & Apache as a foreground process

### Include Ansible drop-ins

Just a folder containing a valid playbook into the container:

    docker run -it -p 8443:443 -v $(pwd)/my_ansible_dropin:/root/ansible_dropin consol/omd-labs-debian


### Login & Password

When starting the container, OMD will create a random default password for the omdadmin user.
There are several ways to handle this:

1. using the data volume will bring your own htpasswd file
2. set your default omdadmin password per ansbible dropin, ex. like:

playbook.yml:
```
---
- hosts: all
  tasks:
  - shell: sudo su - demo -c "set_admin_password omd"
```


### Debugging

If you want to see more verbose output from Ansible to debug your role, adjust the environment variable value [`ANSIBLE_VERBOSITY`](http://docs.ansible.com/ansible/latest/debug_module.html) to e.g. `3`:

    docker run -it -p 8443:443 -e ANSIBLE_VERBOSITY=3 -v $(pwd)/my_ansible_dropin:/root/ansible_dropin consol/omd-labs-debian
