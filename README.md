# omd-labs-docker

OMD "Labs" Edition (<https://omd.consol.de/docs/omd/>) on Docker with Ansible support.

Author: Sven Nierlein, *sven.nierlein at consol.de*

Original Author: Simon Meggle

- <https://omd.consol.de/docs/omd/>
- <https://github.com/ConSol-Monitoring/omd-labs-docker>

## Automated builds, branches & tags

Each image build gets triggered by the OMD Labs build system as soon as there are new packages of OMD available:

- <https://hub.docker.com/r/consol/omd-labs-rocky/>  (x86 / arm64)
- <https://hub.docker.com/r/consol/omd-labs-debian/> (x86 / arm64)

Automated builds are triggered for the following branches:

- *master* => **:nightly** (=snapshot builds)
- *vX.XX*  => **:vX.XX**   (=stable version)
- *latest* => **:latest**  (=latest stable version)

Each image already contains a "demo" site.

## Usage

### run the "demo" site

Run the "demo" site in OMD Labs Edition:

```bash
# Rocky 9
docker run -p 8443:443 consol/omd-labs-rocky
# Debian 13
docker run -p 8443:443 consol/omd-labs-debian
```

Use the Makefile to work with *locally built* images:

```bash
# run a local image
make -f Makefile.omd-labs-rocky start
# build a "local/" image without overwriting the consol/ image
make -f Makefile.omd-labs-rocky build
# start just the bash
make -f Makefile.omd-labs-rocky bash
```

The container will log its startup process:

```txt
Config and start OMD site: demo
--------------------------------------
Checking for volume mounts...
--------------------------------------
 * demo/           [OK]
 * demo/etc/       [OK]
 * demo/var/       [OK]
 * demo/local/     [OK]



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

### Custom sites

#### Change the default sitename

The *default sitename* "demo" can be changed. Build a custom image while `SITENAME` is set:

- clone this repository, `cd` into the folder containg the Dockerfile, e.g. `omd-labs-rocky`
- build a local image:

```bash
export SITENAME=mynewsite; make -f Makefile.omd-labs-rocky build
```

Each container instance of this image will start the site "mynewsite" instead of "demo".

#### Add another site dynamically

If you need to set the *sitename dynamically* without building the whole image from scratch (see above), you can create images with another OMD-site beneath the default site (see above). Create a custom `Dockerfile` which uses the original image as the base image:

```dockerfile
FROM: consol/omd-labs-rocky:nightly
...
...
```

The sitename in your custom OMD image can now be changed by setting the variable `NEW_SITENAME` to a new value:

```bash
export NEW_SITENAME=anothersite
```

The ONBUILD commands in the original Dockerfile execute after the current Dockerfile build completes. ONBUILD executes in any child image derived FROM the current image. Think of the ONBUILD command as an instruction the parent Dockerfile gives to the child Dockerfile.

### Use data containers

#### Host mounted data folders

As soon as the container dies, all monitoring data (configuration files, RRD data, InfluxDB, log files etc.) are lost, too. To keep the data persistent, use host mounted volumes.

This command

```bash
make -f Makefile.omd-labs-rocky startvol
```

starts the container with a volume mount for the site folder:

- `./site/`   => `$OMD_ROOT/`

On the very first start, this folders will be initialized and populated.

Note: previously 3 separate mounts were used for `local/`, `etc/` and `var/`. This is still possible, but it is recommended to use a single mount for the whole site folder.

## Ansible drop-ins

OMD-Labs comes with **full Ansible support**, which we can use to modify the container instance *on startup*.

### Start Sequence

By default, the OMD-labs containers start with the CMD `/root/start.sh`. This script

- checks if there is a `playbook.yml` in `$ANSIBLE_DROPIN` (default: `/root/ansible_dropin`, changeable by environment). If found, the playbook is executed. It is completely up to you if you only place one single task in `playbook.yml`, or if you also include Ansible roles. (with a certain point of complexity, you should think about a separate image, though...)
- starts the OMD site "demo"
- runs system Apache in background
- waits forever

### Include Ansible drop-ins

Just a folder containing a valid playbook into the container:

```bash
docker run -it -p 8443:443 -v $(pwd)/my_ansible_dropin:/root/ansible_dropin consol/omd-labs-debian
```

### Login & Password

When starting the container, OMD will create a random default password for the omdadmin user.
There are several ways to handle this:

1. using the data volume will bring your own htpasswd file
2. set your default omdadmin password per ansbible dropin, ex. like:

playbook.yml:

```yaml
---
- hosts: all
  tasks:
  - shell: sudo su - demo -c "set_admin_password omd"
```

### Debugging

If you want to see more verbose output from Ansible to debug your role, adjust the environment variable value [`ANSIBLE_VERBOSITY`](http://docs.ansible.com/ansible/latest/debug_module.html) to e.g. `3`:

```bash
docker run -it -p 8443:443 -e ANSIBLE_VERBOSITY=3 -v $(pwd)/my_ansible_dropin:/root/ansible_dropin consol/omd-labs-debian
```
