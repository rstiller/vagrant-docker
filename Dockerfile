FROM phusion/baseimage:latest

ENV HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
ADD id_rsa_vagrant.pub /tmp/
RUN cat /tmp/id_rsa_vagrant.pub >> /root/.ssh/authorized_keys
RUN apt-get update -qq
RUN apt-get install -qq -y --force-yes --no-install-recommends puppet chef

CMD ["/sbin/my_init"]

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
