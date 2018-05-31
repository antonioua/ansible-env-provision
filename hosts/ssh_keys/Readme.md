upload_ssh_key_to_remote.sh
<<<

#!/bin/bash

your_host="gitlab"
your_ssh_user=antonku
echo "Enter ssh Password:"
read -s SSHPASS
export SSHPASS=${SSHPASS}
# By default, SUDO is configured to require a TTY, Multiple -t options force tty allocation, even if ssh has no local tty.
ssh_opts="-o StrictHostKeyChecking=no -o Port=22 -o ConnectTimeout=10 -t -t"

key_pub=$( cat id_rsa.pub )

eval sshpass -e ssh ${ssh_opts} ${your_host} -l ${your_ssh_user} << EOF
	sudo useradd ansibleprovision | true
	sudo mkdir -p /home/ansibleprovision/.ssh
	echo "${key_pub}"| sudo tee -a /home/ansibleprovision/.ssh/authorized_keys
	sudo chmod 0700 /home/ansibleprovision/.ssh/authorized_keys
	sudo usermod -a -G wheel ansibleprovision
	exit
EOF