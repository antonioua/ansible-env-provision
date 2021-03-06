
# How To

---
## List of plays below




## Manging application configuration files

* Push application configuration files to certain vm group
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_configure_application_node.yml -e "hosti=host1111" -t "push_configs"
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_configure_application_node.yml -e "hosti=['host1', ''host2]" -t "push_all,start_application" -vvv
~~~

* Push application configuration files to certain vm group with python-simplejson required libs for ansible on remote
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_configure_application_node.yml -e "hosti=dev5" -t "bootstrap,push_configs"
~~~

* Push application configuration files to certain vm group and restart application
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_configure_application_node.yml -e "hosti=dev5" -t "push_configs,start_application"
~~~



## Manging additional files and packages on the vms

* Install phantomjs dependency packages required for crawler.js (for SEO)
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_send_stuff_to_application_node.yml -e "hosti=dev-hosts-all" -t "bootstrap,send_phantomjs_libs"
~~~

* Send jmx jars to vm
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_send_stuff_to_application_node.yml -e "hosti=dev5" -t "send_jmx"
~~~



## Managing zabbix monitoring agent installation and configuration

* Install zabbix agent and configure it on vm group, if needed you can aslo install python-simplejson wioth "bootstrap" tag
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini zabbix_install_agent.yml -e "hosti=dev5" -t "bootstrap,install_zabbix""
$ ansible-playbook -i ./hosts/openapi/prod/openapi_production_all.ini zabbix_install_agent.yml -e "hosti=oapi03-pub-gc.coral.domain1" -t "bootstrap,install_zabbix"
~~~

* Stop zabbix agent
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini zabbix_install_agent.yml -e "hosti=dev5" -t "disable_zabbix"
~~~



## Usefull stuff that can help you during development

* Gather all facts or get a certain fact
~~~bash
$ ansible localhost -m setup -a 'filter=ansible_os_family'
$ ansible wpl-dev5-adminpor1.wpl.domain1 -i ./hosts/application/dev/application_dev_all.ini -m setup -a 'filter=facter_*'
$ ansible wpl-dev5-adminpor1.wpl.domain1 -i ./hosts/application/dev/application_dev_all.ini -m setup -a 'filter=ansible_eth[0-2]'
$ ansible wpl-dev5-adminpor1.wpl.domain1 -i ./hosts/application/dev/application_dev_all.ini -m setup -a 'filter=ansible_os_family'
$ ansible all -i hosts/application/prod/application_production_all.ini -m setup -a 'filter=ansible_distribution_version' -e 'gather_facts=True' --limit 'project.com-dev,project.com-tst,project.com-stg,project.com-perf,project.com-prod,project.be-tst,project.be-stg,project.be-prod,prj3-tst,prj3-tst2,prj3-stg,prj3-stg2,prj3-prod-wpl2,prj3-prod-wpl3,prj3-perf-wpl3,prj3-perf-wpl2,prj2-tst,prj2-stg,prj2-perf,prj2-prod-prj4,prj2-prod-hub-migration,prj5-tst,prj5-stg,prj5-prod'
# show OS version for all wpl3 pr1 envs
$ ansible all -i hosts/application/prod/application_production_all.ini -m setup -a 'filter=ansible_distribution_version' -e 'gather_facts=True' --limit 'prj3-tst2,prj3-stg2,prj3-prod-wpl3,prj3-perf-wpl3,prj2-tst,prj2-stg,prj2-perf,prj2-prod-prj4,prj2-prod-hub-migration,prj5-tst,prj5-stg,prj5-prod'
# grep all prj2 vms with Centos 5
$ ansible all -i hosts/application/prod/application_production_all.ini -m setup -a 'filter=ansible_distribution_version' -e 'gather_facts=True' --limit 'prj3-tst2,prj3-stg2,prj3-prod-wpl3,prj3-perf-wpl3,prj2-tst,prj2-stg,prj2-perf,prj2-prod-prj4,prj2-prod-hub-migration,prj5-tst,prj5-stg,prj5-prod' | grep "5" -B2 | grep "\"5" -B2
~~~

* Dry-run + check diffs
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_configure_application_node.yml -e "hosti=['wpl-dev5-adminpor1.wpl.domain1']" -t "push_configs" --check --diff
~~~

* Ping the remote host
~~~bash
$ ansible all -i ./hosts/application/dev/application_dev_all.ini --module-name ping -e "hosti=application-dev-nw" --limit wpl-dev5-adminpor1.wpl.domain1
~~~

* Show the list of hosts that will be affected by playbook
~~~bash
$ ansible-playbook -i ./hosts/application/dev/application_dev_all.ini application_configure_application_node.yml -e "hosti=application-dev-nw" --limit wpl-dev5-adminpor1.wpl.domain1 --list-hosts
~~~

* Install "python-simplejson" on group of hosts manualy
~~~bash
$ ansible all -i ./hosts/application/dev/application_dev_all.ini -e "hosti=dev-hosts-all" --limit wpl-dev5-adminpor1.wpl.domain1  -m raw -a "sudo yum install -y python-simplejson"
~~~

* Run any command on remote server
~~~bash
$ ansible all -i ./hosts/application/dev/application_dev_all.ini -e "hosti=dev-hosts-all" --limit wpl-dev5-adminpor1.wpl.domain1 -m raw -a "rm -rf /tmp/.ansible/"
~~~

* Inject any task in cmd
~~~bash
$ ansible wpl-dev5-adminpor1.wpl.domain1 -m file -a "state=link src=/usr/share/zoneinfo/Europe/Location1 dest=/etc/localtime" -vvv
~~~

* Gather facts from remote server
~~~bash
$ ansible all -i hosts/application/dev/application_dev_all.ini -m setup --tree /tmp/facts --limit wpl-dev5-adminpor1.wpl.domain1
~~~

* Stuff
~~~bash
$ for i in `grep "# project: project" . -R | grep -v prod | cut -d'/' -f6`; do echo "processing $i"; arr1+=("$i"); done
$ echo ${arr1[@]} | sed -e "s/ /\',\'/g"
$ ansible-playbook -i hosts/application/prod/application_production_all.ini application_configure_application_node.yml -e "hosti=['applicationTEST-blue-wpl-privil-admin-01.redbutton.domain1','wpl-dev5-adminpor1.wpl.domain1']" -t "push_configs"
$ sudo yum downgrade ansible.noarch
~~~

* push log4j.xml
~~~bash
$ ansible-playbook -i ./hosts/application/prod/application_production_all.ini application_configure_application_node.yml -e "hosti=['host1', 'host2'] log4j_file=present" -t "push_configs"
$ ansible-playbook -i ./hosts/application/prod/application_production_all.ini application_configure_application_node.yml -e "hosti=['host1', 'host2'] log4j_file=present" -t "push_configs,start_application"
~~~

* push configs and restart vms in certain groups
~~~bash
$ ansible-playbook -i ./hosts/application/prod/application_production_all.ini application_configure_application_node.yml -e "hosti=application-prod-nw" -t "push_configs,start_application" --limit prj3-tst2,prj2-tst,prj2-stg,prj2-perf  --list-hosts
$ ansible-playbook -i ./hosts/application/prod/application_production_all.ini application_configure_application_node.yml -e "hosti=application-prod-nw" -t "push_configs,start_application" --limit prj3-tst2,prj2-tst,prj2-stg,prj2-perf
~~~

## Produce configs for third-parties
~~~bash
$ mkdir -p /opt/local/tmp
$ ansible-playbook -i hosts/application/prod/application_production_all.ini application_configure_application_node.yml -e "hosti=all" -t "produce_configs" --limit host1
~~~

-D maybe shows diff between files

## ToDo
* add middleware setup role
Install jdk8.60
~~~bash
$ ansible-playbook -i ./hosts/application/prod/application_production_all.ini application_middleware_setup.yml -e "hosti=['host1', 'host2']"
$ ansible-playbook -i ./hosts/application/prod/application_production_all.ini application_middleware_setup.yml -e "hosti=prj2-stg"
~~~
* enable fact gathering
* setup eth0 ip in wpl.boot.conf from facts



* New tags:
- sweep_up (clear application's heap dumps and package-old-*)


* Push jks_t.keystore to update CDN intermediate certificate:
~~~bash
ansible-playbook -i hosts/application/prod/application_production_all.ini application_configure_application_node.yml -e 'hosti=node1.domain1' -t push_trust_keystore
~~~

* Get vms list without new lines
~~~bash
$ grep "prj2-" /home/antonku/Documents/pycharm-prjs/automatization/ansible-env-provision/hosts/application/prod/application_production_all.ini |grep -v "\[" | sed -e "s/^/\'/g" -e "s/$/\',/g" | tr -d '\n'
~~~


# On old Centos 5 where python2.4 is installed just do (files are available on ifra gw),deps are: <br/>
ssh loc1gw.domain1:/home/antonku/python_inst
libffi-3.0.5-1.el5.x86_64.rpm <br/>
python26-2.6.8-2.el5.x86_64.rpm <br/>
python26-libs-2.6.8-2.el5.x86_64.rpm <br/>
~~~bash
$ sudo yum install epel-release
$ sudo yum install python26.x86_64
$ sudo mv /usr/bin/python /usr/bin/python.bak && sudo ln -s /usr/bin/python26 /usr/bin/python
~~~
