#!/bin/bash

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
echo 'deb https://get.docker.io/ubuntu docker main' > /etc/apt/sources.list.d/docker.list
apt-get -qq update
apt-get install -qq -y --force-yes lxc-docker

# enable vagrant to use docker without sudo
adduser vagrant docker

# pull base image
docker pull phusion/baseimage:latest

# create private key if necessary
if [ ! -f /vagrant/id_rsa_vagrant ]; then
    ssh-keygen -b 2048 -t rsa -f /vagrant/id_rsa_vagrant -q -N ''
fi

# split ports argument using comma
IFS=',' read -a PORTS <<< "${2}"
PORT_OPTIONS=""

# gather port options for docker container
for p in "${PORTS[@]}"
do
    if [ "${p}" != "22" ]; then
        PORT_OPTIONS="${PORT_OPTIONS} -p ${p}"
    fi
done

# change current working directory
cd /vagrant
# build docker container
docker build --rm --force-rm=true --tag="${3}" .

docker ps -a | grep -q -c $1

if [ $? -ne 0 ]; then
    # run docker container as daemon
    docker run -d \
        --name="${1}" \
        --hostname="${1}" \
        --privileged=true --workdir='/vagrant/' \
        --volume='/etc/localtime:/etc/localtime:ro' \
        --volume='/vagrant:/vagrant:rw' \
        $PORT_OPTIONS \
        -p 2222:22 \
        -t "${3}"
fi

mkdir -p /home/vagrant/.ssh/tmp
chown -R vagrant:vagrant /home/vagrant/.ssh/tmp

read -d '' INIT_SCRIPT <<"INIT_SCRIPT_END"
[Unit]
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a __CONTAINER_NAME__
ExecStop=/usr/bin/docker stop -t 2 __CONTAINER_NAME__

[Install]
WantedBy=local.target
INIT_SCRIPT_END

read -d '' SSH_CONFIG <<"SSH_CONFIG_END"
ControlMaster auto
ControlPath /home/vagrant/.ssh/tmp/%h_%p_%r

Host docker
    HostName 127.0.0.1
    Port 2222
    User root
    IdentityFile /home/vagrant/.ssh/id_rsa_vagrant
SSH_CONFIG_END

echo "${INIT_SCRIPT//__CONTAINER_NAME__/$1}" > /etc/init/docker_container.conf
echo "${SSH_CONFIG}" > /home/vagrant/.ssh/config
cp /vagrant/id_rsa_vagrant* /home/vagrant/.ssh/
chmod 0600 /home/vagrant/.ssh/id_rsa_vagrant /home/vagrant/.ssh/config
chown -R vagrant:vagrant /home/vagrant/.ssh/id_rsa_vagrant* /home/vagrant/.ssh/config

# redirect all other ports than 22 to docker container
for p in "${PORTS[@]}"
do
    if [ "${p}" != "22" ]; then
        iptables -t nat -A PREROUTING -i eth0 -p tcp --dport $p -j REDIRECT --to-port `docker port $1 $p | cut -d':' -f 2`
    fi
done
