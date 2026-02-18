# Secure and harden an Ubuntu server

> Forked from [shiroyasha/secure-server](https://github.com/shiroyasha/secure-server) and is maintained separately.

You use this script first thing after creating your virtual server. It's suitable for [OpenClaw](https://github.com/openclaw/openclaw) and other agents.

## Features

- Upgrade system packages
- Install Docker and Docker Compose
- Configure UFW firewall (custom SSH port, HTTP, HTTPS)
- Harden SSH (disable root login, password auth, and empty passwords; enable public key auth)
- Create a non-root `app` user with sudo and Docker access
- Import SSH public keys from GitHub for the `app` user
- Install and configure fail2ban against brute-force attacks
- Secure shared memory

## Usage

### 1/ SSH into your server as root

```bash
ssh root@your-server-ip
```

### 2/ Optionally set the `GITHUB_USERNAME` environment variable.

```bash
export GITHUB_USERNAME=your_username
```

If not set, the script will prompt you for it interactively.

### 3/ Run the hardening script.

```bash
curl -fsSL https://raw.githubusercontent.com/kkomelin/secure-ubuntu-server/main/harden.sh | bash
```

The script will also prompt for an SSH port (default: `20202`).

### 4/ Use your new `app` user to SSH into your server.

```bash
ssh -p 20202 app@your-server-ip
```
