#!/usr/bin/env bash

#
# Applies common security measures for Ubuntu servers.
#
# Usage: ./harden.sh
#    or: GITHUB_USERNAME=your_username SSH_PORT=20202 ./harden.sh
#
# Prompts for GITHUB_USERNAME and SSH_PORT if not provided via env vars.
# Fetches the GitHub user's SSH public keys and adds them to the app user's
# authorized_keys. Afterwards, you'll only be able to SSH into the server
# as 'app', e.g. app@1.2.3.4
#

set -e

export DEBIAN_FRONTEND=noninteractive

if [ -z "${GITHUB_USERNAME}" ]; then
    read -rp "Enter your GitHub username: " GITHUB_USERNAME </dev/tty
    if [ -z "${GITHUB_USERNAME}" ]; then
        echo "Error: GitHub username is required."
        exit 1
    fi
fi

if [ -z "${SSH_PORT}" ]; then
    read -p "SSH port [20202]: " SSH_PORT </dev/tty
    SSH_PORT=${SSH_PORT:-20202}
fi

# ---------------------------------------------------------
# Step 1: Update and upgrade system packages
# ---------------------------------------------------------

# Configure 'needrestart' for auto-restart of services after upgrades
sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf

apt update -y
apt upgrade -y -o Dpkg::Options::="--force-confold"
apt install -y vim nano mc curl htop jq

# ---------------------------------------------------------
# Step 2: Create Non-Root User and Set Up SSH Access
# ---------------------------------------------------------

echo "Setup app user"
adduser --disabled-password --gecos "" app
echo "app ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

sudo -H -u app bash -c 'mkdir -p ~/.ssh'
sudo -H -u app bash -c 'chmod 700 ~/.ssh'

echo "Fetching SSH keys from GitHub for user: $GITHUB_USERNAME"
KEYS_FILE=$(mktemp)
trap 'rm -f "$KEYS_FILE"' EXIT
curl -sf "https://api.github.com/users/${GITHUB_USERNAME}/keys" | jq -r '.[].key' | grep -v '^$' > "$KEYS_FILE"
if [ ! -s "$KEYS_FILE" ]; then
    echo "Error: No SSH keys found for GitHub user '$GITHUB_USERNAME'. Check the username and try again."
    exit 1
fi

sudo -H -u app bash -c 'touch ~/.ssh/authorized_keys'
sudo -H -u app bash -c 'chmod 600 ~/.ssh/authorized_keys'
cp "$KEYS_FILE" /home/app/.ssh/authorized_keys
chown app:app /home/app/.ssh/authorized_keys
chmod 600 /home/app/.ssh/authorized_keys

# ---------------------------------------------------------
# Step 3: Install Docker and Docker Compose
# ---------------------------------------------------------

# Update package list and install prerequisites
apt install -y ca-certificates gnupg

# Add Docker's official GPG key and set up repository
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker and Docker Compose plugins
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add app user to Docker group
usermod -aG docker app

# ---------------------------------------------------------
# Step 4: Configure Virtual Memory Overcommit
# ---------------------------------------------------------

sysctl vm.overcommit_memory=1
echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf

# ---------------------------------------------------------
# Step 5: Configure UFW Firewall
# ---------------------------------------------------------

ufw allow "$SSH_PORT"/tcp
ufw allow http
ufw allow https
ufw --force enable

# ---------------------------------------------------------
# Step 6: Secure SSH Configuration
# ---------------------------------------------------------

sed -i -e '/^\(#\|\)Port /s/^.*$/Port '"$SSH_PORT"'/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PubkeyAuthentication/s/^.*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PermitEmptyPasswords/s/^.*$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config

if ! grep -q "^ChallengeResponseAuthentication" /etc/ssh/sshd_config; then
    echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config
else
    sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
fi

# ---------------------------------------------------------
# Step 7: Install and Configure fail2ban
# ---------------------------------------------------------

echo "Setup fail2ban"
apt install -y fail2ban

cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
maxretry = 5
findtime = 600
bantime = 600
ignoreip = 127.0.0.1/8
logpath = /var/log/auth.log
EOF


# ---------------------------------------------------------
# Step 8: Secure Shared Memory
# ---------------------------------------------------------

echo "Secure shared memory"
echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab

# ---------------------------------------------------------
# Step 9: Reboot to Apply Changes
# ---------------------------------------------------------

echo "Rebooting so changes can take effect"
reboot
