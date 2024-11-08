help:
	@echo "install - install dependencies and requirements"
	@echo "swap-on - allocate swap"
	@echo "save-git-credential - save git credential"
	@echo "ram-disk - resize ram disk (default = 2 GB)"


install:  inst_basics inst_python inst_projects inst_tools inst_sql 


inst_basics:
	yes | sudo dnf upgrade && sudo dnf update

inst_python:
	yes | sudo dnf install --upgrade python3-pip -y  # install pip

inst_projects:
	git clone https://github.com/venoajie/App.git
	mv App ..

inst_tools:	
	curl https://rclone.org/install.sh | sudo bash
	curl -LsSf https://astral.sh/uv/install.sh | sh

inst_sql:
	yes | sudo apt install postgresql sqlite3	
	yes | sudo apt-get upgrade && sudo apt update
