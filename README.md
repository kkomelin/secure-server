# secure-ubuntu-server

One-liner security hardening for Ubuntu servers.

Run this script first thing after creating your virtual server.

It's suitable for servers with [OpenClaw](https://github.com/openclaw/openclaw) and other agents.

## What it does

- Upgrade system packages
- Create a non-root `app` user with sudo access and import SSH public keys from GitHub
- Install Docker and Docker Compose, add `app` to the Docker group
- Configure UFW firewall (custom SSH port, HTTP, HTTPS)
- Harden SSH (disable root login, password auth, and empty passwords; enable public key auth)
- Install and configure fail2ban against brute-force attacks
- Secure shared memory
- Reboot to apply changes

## Usage

> Your GitHub account must have at least one [SSH key](https://github.com/settings/keys) added. The script will exit if none are found, before any changes take effect.

### 1. SSH into your server as root

```bash
ssh root@your-server-ip
```

### 2. Optionally set environment variables

```bash
export GITHUB_USERNAME=your_username
export SSH_PORT=20202
```

If not set, the script will prompt for each interactively. `SSH_PORT` defaults to `20202`.

### 3. Run the hardening script

```bash
curl -fsSL https://raw.githubusercontent.com/kkomelin/secure-ubuntu-server/main/harden.sh | bash
```

### 4. Use your new `app` user to SSH into your server

```bash
ssh -p 20202 app@your-server-ip
```

## Credits

_Forked from [shiroyasha/secure-server](https://github.com/shiroyasha/secure-server) and is now maintained separately._
