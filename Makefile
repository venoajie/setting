install:  inst-basics inst_python inst_projects inst_tools inst_oci save-git-credential inst_gpg_key_for_terraform inst_terraform#inst_sql 

# Update and upgrade system packages
inst-basics:
	sudo NEEDRESTART_MODE=a apt-get dist-upgrade --yes
	sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
	yes | sudo apt upgrade && sudo apt update

# Install Python and related tools
inst_python:
	yes | sudo apt install --upgrade python3-pip -y  # install pip
	sudo ln -s /usr/bin/python3 /usr/local/bin/py # python3 to py
	yes | sudo apt install python3-dev python3-pip python3-venv python3-virtualenv pipx python3-setuptools
	pipx install dotlink
	yes | sudo apt upgrade && sudo apt update

# Clone and move project repository
inst_projects:
	git clone https://github.com/venoajie/App.git
	mv App ..


# Install various tools and utilities
inst_tools:	
	yes | sudo apt upgrade && sudo apt update
	yes | sudo apt install docker.io redis-server docker-compose
	yes | sudo apt install rabbitmq-server
	yes | sudo rabbitmq-plugins enable rabbitmq_management
	sudo systemctl enable rabbitmq-server && sudo systemctl start rabbitmq-server
	sudo chmod 666 /var/run/docker.sock
	yes | sudo apt install --upgrade wl-clipboard # perform "+y to yank from Neovim to your system clipboard
	curl https://rclone.org/install.sh | sudo bash
	curl -LsSf https://astral.sh/uv/install.sh | sh
	dotlink https://github.com/venoajie/dotfiles.git
	sudo usermod -aG docker $USER #Add current user to docker group
	sudo chown $USER /var/run/docker.sock #Change the permissions of docker socket to be able to connect to the docker daemon

# Additional references for tools installation
# https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-redis-on-ubuntu-20-04
# https://samedwardes.com/blog/2024-04-21-python-uv-workflow/
# https://levelup.gitconnected.com/python-dependency-war-uv-vs-pip-86762c37fcab	
# https://medium.com/bitgrit-data-science-publication/forget-pip-install-use-this-instead-754863c58f1e
# https://medium.com/@gnetkov/start-using-uv-python-package-manager-for-better-dependency-management-183e7e428760
# https://hostman.com/tutorials/task-queues-with-celery-and-rabbitmq/
# https://stackoverflow.com/questions/48957195/how-to-fix-docker-permission-denied

# Install SQL databases
inst_sql:
	yes | sudo apt install postgresql sqlite3	
	yes | sudo apt-get upgrade && sudo apt update
	#sudo reboot
	sudo apt-get clean

# Install Oracle Cloud Infrastructure CLI
inst_oci:
	bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh --accept-all-defaults)" 
	exec -l $SHELL
	source $HOME/.local/bin/env # Add the CLI to your PATH 
	git config --global credential.helper store
	sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8501 -j ACCEPT
	sudo netfilter-persistent save
	# https://www.reddit.com/r/oraclecloud/comments/r8lkf7/a_quick_tips_to_people_who_are_having_issue/
	# https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__linux_and_unix
	# directory: cd /home/ubuntu/.oci

inst_terraform:
	# https://learn.hashicorp.com/tutorials/terraform/install-cli
	# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-terraform-on-ubuntu-20-04
	yes | sudo apt install unzip
	yes | sudo apt install wget
	wget https://releases.hashicorp.com/terraform/1.12.0/terraform_1.12.0_linux_arm64.zip
	unzip terraform_1.12.0_linux_arm64.zip
	sudo mv terraform /usr/local/bin/
	rm terraform_1.12.0_linux_arm64.zip
	sudo chmod +x /usr/local/bin/terraform

inst_gpg_key_for_terraform:
	#https://stackoverflow.com/questions/75254685/gpg-error-https-apt-releases-hashicorp-com-bionic-inrelease-the-following-si
	# GPG is required for the package signing key
	sudo apt install gpg

	# Download the signing key to a new keyring
	wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

	# Verify the key's fingerprint
	gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

	# The fingerprint must match 798A EC65 4E5C 1542 8C8E 42EE AA16 FCBC A621 E701, which can also be verified at https://www.hashicorp.com/security under "Linux Package Checksum Verification".

	# Add the HashiCorp repo
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

	# apt update successfully
	sudo apt update
	# Save Git credentials globally


save-git-credential:
	git config --global credential.helper store

# Activate systemd services
activate_service:
	sudo systemctl daemon-reload
	sudo chmod +x /etc/systemd/system/sync_with_remote.service
	sudo systemctl enable sync_with_remote.service
	sudo systemctl start sync_with_remote.service
	sudo chmod +x /etc/systemd/system/app.service
	sudo systemctl enable app.service
	mv service ..

# Clone and move dotfiles repository
inst_dot:
	git clone https://github.com/venoajie/App.git
	mv App ..

# Create RAM disk for databases
ram-disk:
	# https://towardsdev.com/linux-create-a-ram-disk-to-speed-up-your-i-o-file-operations-18dcaede61d2
	sudo mount -t tmpfs -o rw,size=1G tmpfs src/databases/market
	sudo chmod 777 src/databases/market
	sudo mount -t tmpfs -o rw,size=1G tmpfs src/databases/exchanges
	sudo chmod 777 src/databases/exchanges
	git pull

# Configure swap space
swap-on:
	# https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04 
	# https://askubuntu.com/questions/927854/how-do-i-increase-the-size-of-swapfile-without-removing-it-in-the-terminal
	set -e  # bail if anything goes wrong
	swapon --show               # see what swap files you have active
	sudo swapoff --all
	# Create a new 4 GiB swap file in its place (could lock up your computer 
	# for a few minutes if using a spinning Hard Disk Drive [HDD], so be patient)
	sudo dd if=/dev/zero of=/swapfile bs=512M count=8
	sudo mkswap /swapfile       # turn this new file into swap space
	sudo chmod 0600 /swapfile   # only let root read from/write to it, for security
	sudo swapon /swapfile       # enable it
	swapon --show               # ensure it is now active
	sudo sysctl vm.swappiness=10 # update swappiness to 10
	sudo sysctl vm.vfs_cache_pressure=50 # update cache pressure to 50
	sudo cp /etc/fstab /etc/fstab.bak
	echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
	sudo reboot                    

inst_non_basics:
	sudo NEEDRESTART_MODE=a apt-get dist-upgrade --yes
	sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
	yes | sudo apt upgrade && sudo apt update
	# Install essential build tools and libraries
	yes | sudo apt install --upgrade -y build-essential gdb lcov pkg-config libbz2-dev 
	yes | sudo apt install --upgrade -y libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev libncurses5-dev libreadline-dev libsqlite3-dev libssl-dev lzma lzma-dev tk-dev uuid-dev
	yes | sudo apt install --upgrade -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl 
	yes | sudo apt install --upgrade -y llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
	# Install Perl libraries
	yes | sudo apt install --upgrade  -y libdigest-hmac-perl libgssapi-perl libcrypt-ssleay-perl libsub-name-perl 
	yes | sudo apt install --upgrade  -y libbusiness-isbn-perl libauthen-ntlm-perl libunicode-map8-perl libunicode-string-perl xml-twig-tools nickle cairo-5c xorg-docs-core
	yes | sudo apt install --upgrade  -y libgd-barcode-perl librsvg2-bin xorg-docs  linux-image- 
	yes | sudo apt-get upgrade && sudo apt update
