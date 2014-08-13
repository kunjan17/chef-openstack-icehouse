Jumpstart
==========
Bootstrap script installs knife-solo, downloads necessary cookbooks from git and starts All-in-one installation process 

1. Install CentOS 6.4 minimal http://mirror.yandex.ru/centos/6.4/isos/x86_64/CentOS-6.4-x86_64-minimal.iso
   
   **Note.** LVM volume group is required for cinder. Use logical volumes during installation or create your own VG before processing
  

2. Execute as root user

  ``` console
  curl -s https://raw.github.com/laboshinl/openstack-havana-cookbook/master/bootstrap.sh | bash
  ```

3. Reboot
4. Change addreses in /root/floating-pool.sh and run it to create neutron external network
5. All done! Go to http://ipaddress/dashboard  login: **admin** password: **mySuperSecret**

  **Note.** Swift will not work until you mount any disk at /srv/node/device. 
  ```
  mount /dev/your_disk /srv/node/device

  chown swift.swift /srv/node/device
  
  swift-init main restart
  ```
  Don't forget to mount it in fstab.

centos_cloud Cookbook
=====================

This cookbook installs openstack "havana".

####Neutron: 
- vlan
- openvswitch 
- namespaces

####Compute: 
- kvm

####Glance: 
- swift backend

####Cinder: 
- lvm driver

####Includes:
- heat 
- ceilometer
- swift

Requirements
------------
#### OS

- CentOS 6.4 minimal x86_64

#### Interfaces

- At least one network interface on controller and nodes

#### LVM

- Volume group for cinder 

#### cookbooks
- `simple_iptables` - centos_cloud needs simple_iptables to manage iptables.
- `libcloud` -  centos_cloud needs libcloud to use scp, manage ssh-keys, etc.
- `selinux` - centos_cloud needs selinux to disable selinux.
- `tar` - centos_cloud needs tar to manage tar.gz

#### databags
- openstack 

```
$ knife data bag show ssh_keypairs openstack
id : openstack
private_key: -----BEGIN RSA PRIVATE KEY----- ... -----END RSA PRIVATE KEY-----
public_key: ssh-rsa ... user@host
```

Attributes
----------

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:creds][:admin_password]</tt></td>
    <td>string</td>
    <td>admin user password</td>
    <td><tt>mySuperSecret</tt></td>
  </tr>
  <tr>
    <td><tt>[:creds][:mysql_password]</tt></td>
    <td>string</td>
    <td>mysql root user password</td>
    <td><tt>r00tSqlPass</tt></td>
  </tr>
  <tr>
    <td><tt>[:creds][:keystone_token]</tt></td>
    <td>string</td>
    <td>keystone token</td>
    <td><tt>c6c5de883bfd0ef30a71</tt></td>
  </tr>
  <tr>
    <td><tt>[:creds][:swift_hash]</tt></td>
    <td>string</td>
    <td>swift hash</td>
    <td><tt>12c51e21fc2824fff5c5</tt></td>
  </tr>
  <tr>
    <td><tt>[:creds][:quantum_secret]</tt></td>
    <td>string</td>
    <td>quantum shared secret</td>
    <td><tt>c6c5de883bfd0ef30a71</tt></td>
  </tr>
  <tr>
    <td><tt>[:creds][:ssh_keypair]</tt></td>
    <td>string</td>
    <td>name of databag containing ssh-keypair </td>
    <td><tt>openstack</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:controller]</tt></td>
    <td>string</td>
    <td>compute node ipaddress</td>
    <td><tt>node[:ipaddress]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:qpid]</tt></td>
    <td>string</td>
    <td>message broker ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:keystone]</tt></td>
    <td>string</td>
    <td>identity service ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:swift]</tt></td>
    <td>string</td>
    <td>objectstore service ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:glance]</tt></td>
    <td>string</td>
    <td>image service  ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:cinder]</tt></td>
    <td>string</td>
    <td>block storage service ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:quantum]</tt></td>
    <td>string</td>
    <td>network service  ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:nova]</tt></td>
    <td>string</td>
    <td>compute service ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:heat]</tt></td>
    <td>string</td>
    <td>cloudformation service ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
  <tr>
    <td><tt>[:ip][:ceilometer]</tt></td>
    <td>string</td>
    <td>metric service ipaddress</td>
    <td><tt>[:ip][:controller]</tt></td>
  </tr>
</table>

Usage
-----

Just include `centos-cloud` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[centos-cloud]"
  ]
}
```
http://[IPADDRESS]/dashboard  
login: admin 
password: mySuperSecret

Add compute node

```json
{
  "ip" : { 
    "controller": "IPADDRESS"
  },
  "run_list": [
    "recipe[centos-cloud::node]"
  ]
}
```



Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Leonid Laboshin
