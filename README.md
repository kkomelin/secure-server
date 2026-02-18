# Secure/harden an Ubuntu server

> Forked from [shiroyasha/secure-server](https://github.com/shiroyasha/secure-server) and is maintained separately.

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

#### 1/ SSH into your server as root

```bash
ssh root@your-server-ip
```

#### 2/ Set the `GITHUB_USERNAME` environment variable to your GitHub username.

```bash
export GITHUB_USERNAME=your_username
```

#### 3/ Run the hardening script.

```bash
curl -fsSL https://raw.githubusercontent.com/kkomelin/secure-ubuntu-server/main/harden.sh | bash -s -e
```

#### 4/ Use your new `app` user to SSH into your server.

```bash
ssh app@your-server-ip
```
