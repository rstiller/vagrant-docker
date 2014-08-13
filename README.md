# vagrant-docker

This is a basic example for the docker vagrant provider.

On linux hosts the [docker](https://www.docker.com/) provider
offers linux container with almost native speed of execution.

On Mac and Windows machines the docker container is
wrapped in a [VirtualBox](http://www.virtualbox.org/) machine.
All exposed ports from the docker container are
passed through the VirtualBox machine except port 22.

## start the vm

from a linux host:

```text
vagrant up --provider=docker
vagrant ssh
```

from a mac / windows host:

```text
vagrant up --provider=virtualbox
vagrant ssh
ssh docker # inside the virtualbox vm
```

If you make changes to the Dockerfile you need
to stop and remove the docker container,
rebuild the image and start a new container.

from a linux host:

```text
vagrant destroy -f
docker rmi <your-base-image-name>
vagrant up --provider=docker
```

from a mac / windows host:

```text
vagrant destroy -f
vagrant up --provider=virtualbox
```
