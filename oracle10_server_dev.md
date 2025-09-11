# Problem with oracle 10 docker installation:
#**both** of Docker's primary installation methods are currently incompatible with a fresh Oracle Linux 10 installation:
#1.  The official DNF repository: **Does not exist.**
#2.  The official convenience script: **Does not support OL10.**

### **The Engineering Pivot: A More Resilient Solution**: When automated methods fail on a new OS, we fall back to a more manual but more controlled process. Since Oracle Linux is a derivative of Red Hat Enterprise Linux (RHEL), we can confidently use the official Docker repository for its closest, stable relative: **CentOS 9**.

#**Action Plan:**
#1.  Create a new script file named `host_setup_v_prod.sh` in your home directory.
#2.  Paste the content below into the file.
#3.  Make it executable: `chmod +x host_setup_v_prod.sh`.
#4.  Run it: `./host_setup_v.sh`.

#--- START OF FILE host_setup_v_prod.sh ---
#!/bin/bash
set -euo pipefail

# --- SRE-1: System Preparation & Tooling (Definitive for OL10) ---
echo "Updating all system packages, excluding the conflicting pyOpenSSL package..."
sudo dnf update -y --exclude=python3-pyOpenSSL

echo "Installing the official EPEL 10 repository configuration..."
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm

echo "Installing essential tools from base and EPEL repositories..."
sudo dnf install -y git htop jq

# --- SRE-1 & SSA-1: Docker Installation (Repository Method) ---
echo "Manually configuring DNF to use the official Docker repository for CentOS 9..."
sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/centos/9/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

echo "Installing Docker Engine and Compose plugin from the newly configured repository..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Enabling and starting the Docker service..."
sudo systemctl enable --now docker

echo "Adding the current user ($USER) to the 'docker' group..."
sudo usermod -aG docker $USER

echo "Applying sysctl changes..."
sudo sysctl --system

echo "Host preparation complete."
echo "!!! CRITICAL: You MUST log out and log back in for all changes to take effect. !!!"
#--- END OF FILE ---
