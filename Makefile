help:
	@echo "install - install dependencies and requirements"
	@echo "swap-on - allocate swap"
	@echo "save-git-credential - save git credential"
	@echo "ram-disk - resize ram disk (default = 2 GB)"


install:
	sudo NEEDRESTART_MODE=a apt-get dist-upgrade --yes
	sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
	yes | sudo apt upgrade && sudo apt update
	yes | sudo apt install inotify-tools sqlite3 borgbackup  docker.io
	yes | sudo apt install --upgrade -y build-essential gdb lcov pkg-config libbz2-dev 
	yes | sudo apt install --upgrade -y libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev libncurses5-dev libreadline-dev libsqlite3-dev libssl-dev lzma lzma-dev tk-dev uuid-dev # https://medium.com/@fsufitch/filips-awesome-overcomplicated-python-dev-environment-dd24ee2a009c
	yes | sudo apt install --upgrade -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl 
	yes | sudo apt install --upgrade -y llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev 	# https://medium.com/@aashari/easy-to-follow-guide-of-how-to-install-pyenv-on-ubuntu-a3730af8d7f0
	yes | sudo apt install --upgrade python3-pip -y  # install pip
	sudo ln -s /usr/bin/python3 /usr/local/bin/py # python3 to py
	yes | sudo apt install python3-dev python3-pip python3-venv python3-virtualenv
	yes | sudo apt upgrade && sudo apt update
	yes | sudo apt install --upgrade wl-clipboard # perform "+y to yank from Neovim to your system clipboard
	git clone https://github.com/venoajie/App.git
	curl https://rclone.org/install.sh | sudo bash
	curl -LsSf https://astral.sh/uv/install.sh | sh # https://samedwardes.com/blog/2024-04-21-python-uv-workflow/
	#https://levelup.gitconnected.com/python-dependency-war-uv-vs-pip-86762c37fcab	
	yes | sudo apt install --upgrade  -y libdigest-hmac-perl libgssapi-perl libcrypt-ssleay-perl libsub-name-perl 
	yes | sudo apt install --upgrade  -y libbusiness-isbn-perl libauthen-ntlm-perl libunicode-map8-perl libunicode-string-perl xml-twig-tools nickle cairo-5c xorg-docs-core
	yes | sudo apt install --upgrade  -y libgd-barcode-perl librsvg2-bin xorg-docs
	mv App ..
	sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
	curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
	yes | sudo apt install postgresql-17
	sudo apt-get clean
	yes | sudo apt-get upgrade && sudo apt update
	sudo systemctl enable postgresql
	python3 -m venv .venv
	yes | sudo apt install pipx
	pipx ensurepath
	sudo reboot
	#python3 -m pip install --user pipx
	#python3 -m pipx ensurepath	
	#pip3 install --upgrade black coverage flake8 mypy pylint pytest tox python-dotenv loguru numpy pandas dask pytest-asyncio websockets requests aiohttp aiosqlite aioschedule dataclassy orjson psutil cachetools

inst_psql:
	sudo apt update
	sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
	curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
	sudo apt update
	sudo apt install postgresql-17
	psql --version
	sudo systemctl start postgresql
	sudo systemctl enable postgresql



ram-disk:
#https://towardsdev.com/linux-create-a-ram-disk-to-speed-up-your-i-o-file-operations-18dcaede61d2
	sudo mount -t tmpfs -o rw,size=1G tmpfs src/databases/market
	sudo chmod 777 src/databases/market
	sudo mount -t tmpfs -o rw,size=1G tmpfs src/databases/exchanges
	sudo chmod 777 src/databases/exchanges
	git pull

swap-on:
# https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04 
#https://askubuntu.com/questions/927854/how-do-i-increase-the-size-of-swapfile-without-removing-it-in-the-terminal
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

save-git-credential:
	git config --global credential.helper store
