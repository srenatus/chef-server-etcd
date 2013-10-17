FROM ubuntu:12.04
EXPOSE 443
MAINTAINER Stephan Renatus "s.renatus@cloudbau.de"

# XXX Change me
# ADD chef-server_11.0.8-1.ubuntu.12.04_amd64.deb /tmp/
# ADD http://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.0.8-1.ubuntu.12.04_amd64.deb /tmp/
ADD http://10.0.0.1:8000/chef-server_11.0.8-1.ubuntu.12.04_amd64.deb /tmp/

WORKDIR /tmp
RUN dpkg -i chef-server_11.0.8-1.ubuntu.12.04_amd64.deb 

# inject this cookbook and the config.rb for chef-solo/etcd-chef
ADD . /tmp/cookbooks/chef-server-etcd
WORKDIR /tmp/cookbooks/chef-server-etcd

# setup: makes etcd-chef a job under the chef-server's runsv supervision
RUN /opt/chef-server/embedded/bin/chef-solo -c config.rb -o chef-server-etcd::setup

# I <3 runit
CMD /opt/chef-server/embedded/bin/runsvdir-start
