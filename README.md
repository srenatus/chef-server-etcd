# Chef server in a Docker container

This cookbook is wrapping [Opscode's `chef-server` cookbook](https://github.com/opscode-cookbooks/chef-server) to provide a Chef server that's running in a [Docker](http://www.docker.io) container and configured by (the host's) [`etcd`](http://coreos.com/docs/etcd/).
This is made possible by [coderranger's `etcd-chef`](https://github.com/coderanger/etcd-chef), which is run by piggy-backing the Omnibus installer's process supervision tree ([runit](http://smarden.org/runit/) FTW) using its embedded `runit` cookbook.

It has been lightly tested using [CoreOS](http://coreos.com), but there's no reason it shouldn't work with "plain" Docker and `etcd`.
As of now, its raison d'être is mainly to satisfy the author's curiosity - any suggestions, thoughts and ideas on how to properly create a reusable container are very welcome.
_This is not a battle-tested solution_ (yet).

## Build the container

Adjust the way the chef-server Omnibus package finds its way into the container in the `Dockerfile`.

1. `git clone git://github.com/srenatus/chef-server-etcd.git`
2. set your host's IP of `etcd_host` in `chef-server-etcd/config.rb`
3. `docker build -rm -t chef/server chef-server-etcd/`

## Use the container

1. get the container (i.e. build it or pull it from your repository)
2. post your `api_fqdn` value to `etcd` (see below)
3. `docker run -v /tmp/logs:/var/log/chef-server sr/chefserveretcd` - note that the first run executes the first `chef-server-ctl reconfigure` of the Omnibus package and thus takes a while.  You can monitor its logs in `/tmp/logs/etcd-chef/current`.
4. fetch your new Chef server's `admin.pem` and `chef-validator.pem` from `etcd`, e.g.

    ```
    curl -LO http://stedolan.github.io/jq/download/linux64/jq 
    chmod +x jq
    curl -L http://127.0.0.1:4001/v1/keys/chef-server/admin.pem  | ./jq -r .value > admin.pem
    curl -L http://127.0.0.1:4001/v1/keys/chef-server/chef-validator.pem  | ./jq -r .value > chef-validator.pem
    ```

5. setup your Chef toolchain to use your new Chef server...

### Etcd

As of now, the only configuration value that is used is `node['chef-server']['configuration']['api_fqdn']`, set via `/v1/keys/chef-server/configuration/api_fqdn`:

```
curl -L http://127.0.0.1:4001/v1/keys/chef-server/configuration/api_fqdn -d value="172.17.42.1"
```

Setting it to the host's IP address, and forwarding a port to the container's port 443 is all that is needed to try this.

Thanks to `etcd-chef`, any changes to this value will trigger a `chef-solo` run inside the container.

## The bootstrap process

1. get and install Omnibus Chef server `.deb`
2. import cookbook `chef-server-etcd`
3. use Omnibus' `chef-solo` to continue bootstrapping via `chef-server-etcd::setup`,
    - getting the `chef-server` cookbook
    - preparing various work arounds
    - installing a `runit_service` using the Omnibus' embedded `runit` cookbook
    - setting the default container `CMD` to the Omnibus package's runsvdir-start,
        - which will first start the `etcd-chef` service,
        - which will pull the configuration from `etcd` and
        - have the `chef-server` cookbook prepare the rest of the supervision tree (as usual with the Omnibus package)

Using the `chef-server` cookbook (respectively the Omnibus package) in a Docker container is by default facing the problem that it tries to start (via Upstart) the `chef-server-runsvdir` job, which will supervise the `/opt/chef-server/service` directory.
The same effect is achieved here by starting the `runsvdir-script` manually and having one of its services (`etcd-chef`) trigger the rest.


# License and Author

Author:: Stephan Renatus (<s.renatus@cloudbau.de>)

Copyright:: 2013, cloudbau GmbH

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
