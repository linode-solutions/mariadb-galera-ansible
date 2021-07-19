# MariaDB Galera Cluster with Ansible

![mariadb-galera-diagram](mariadb-galera-diagram.png)

Deploy a High Availability Galera database cluster using the [Linode Ansible Collection](https://github.com/linode/ansible_linode) and [MariaDB](https://mariadb.com/kb/en/galera-cluster/). Intended to stand up a fresh deployment, including the provisioning of Linode instances. This should _not_ be used for updating an existing deployment. 

**Distributions:**

- Ubuntu 20.04
- Debian 10 

**MariaDB:**
 - 10.3

## Installation
Create a virtual environment to isolate dependencies from other packages on your system.
```
python3 -m virtualenv env
source env/bin/activate
```

Install Ansible collections and required Python packages.
```
pip install -r requirements.txt
ansible-galaxy collection install linode.cloud community.crypto community.mysql
```

## Setup
Put your [vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html#encrypting-content-with-ansible-vault) password in the `vault-pass` file. Encrypt your Linode root password and valid [APIv4 token](https://www.linode.com/docs/guides/getting-started-with-the-linode-api/#create-an-api-token) with `ansible-vault`. Replace the value of `@R34llyStr0ngP455w0rd!` with your own strong password and `pYPE7TvjNzmhaEc1rW4i` with your own access token.
```
ansible-vault encrypt_string '@R34llyStr0ngP455w0rd!' --name 'root_pass'
ansible-vault encrypt_string 'pYPE7TvjNzmhaEc1rW4i' --name 'token'
```

Copy the generated outputs to the `group_vars/galera/secret_vars` file.
```
root_pass: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          39623631373937663866363766353739653134373636333562376134333036666266656166366639
          3933633632663865313238346237306465333737386637310a623037623732643937373865646331
          62306535636531336565383465656333373736663136636431356133316266616530396565346336
          3837363732393432610a366436633664326262343830313662653234373363643836663662333832
          61316235363961323035316666346664626631663834663361626536323836633537363136643866
          6332643939353031303738323462363930653962613731336265
token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          36383638663330376265373564346562656435373464623337313964326134306132663533383061
          6236323531663431613065336265323965616434333032390a396161353834633937656137333231
          35383964353764646566306437623161643233643933653664323733333232613339313838393661
          3862623431373964360a353837633738313137373833383961653230386133313533393765663766
          34656362393962343139303139373562623634656233623661396662346162333938313136363630
          6365653234666565353634653030316638326662316165386637
```

Configure the Linode instance [parameters](https://github.com/linode/ansible_linode/blob/master/docs/instance.rst#id3), `galera_prefix`, `cluster_name`, and SSL/TLS variables in `group_vars/galera/vars`. As with the above, replace the example values with your own. This playbook was written to support `linode/debian10` and `linode/ubuntu20.04` images.
```
# linode vars
ssh_keys: ssh-rsa AAAA_valid_public_ssh_key_123456785== user@their-computer
galera_prefix: galera
cluster_name: POC
type: g6-standard-4
region: ap-south
image: linode/debian10
group: galera-servers
linode_tags: POC

# ssl/tls vars
country_name: US
state_or_province_name: Pennsylvania
locality_name: Philadelphia
organization_name: Linode
email_address: user@linode.com
ca_common_name: Galera CA
common_name: Galera Server
```

## Usage
Run `provision.yml` to stand up the Linode instances and dynamically write your Ansible inventory to the `hosts` file. The playbook will complete when `ssh` becomes available on all instances. 
```
ansible-playbook provision.yml
```

Now run the `site.yml` playbook with the `hosts` inventory file. A pre-check takes place to ensure you're not running it against an existing Galera cluster. Self-signed certificates are generated and pushed to the cluster nodes for securing replication traffic. Enjoy your new MariaDB Galera cluster!
```
ansible-playbook -i hosts site.yml
```

## Author

- Billy Thompson (@rylabs-billy)
