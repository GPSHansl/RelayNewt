# <img src="relaynewt.png" style="width:50px;"/>&nbsp;relaynewt - Postfix Relay
Version 1.0


A minimal Postfix SMTP relay for home networks.


The relay accepts mail only from trusted local clients and routes outgoing
messages to different SMTP providers based on the sender address.

Typical use case:

- firstname.lastname@gmail.com      → smtp.gmail.com
- firstname.lastname@googlemail.com → smtp.gmail.com
- firstname.lastname@gmx.de         → mail.gmx.net
- anything@yourdomain.com           → your domain provider

No local mailboxes are created.

No mail is received from the Internet.

No MX records are required.

---

# Features

- Relay-only SMTP server
- Sender-dependent relayhost selection
- Multiple SMTP providers
- Multiple sender addresses per identity
- Domain wildcard support (e.g. @yourdomain.com)
- Passwords stored separately from configuration
- Docker Compose based deployment
- Debian Bookworm
- Uses the standard Debian Postfix package

---

# Architecture

```
                     +-------------------+
                     | Thunderbird       |
                     +-------------------+
                               |
                               |
                               | SMTP
                               |
                               ▼
                     +-------------------+
                     | Postfix Relay     |
                     +-------------------+
                        │
        ┌───────────────┼───────────────────┐
        │               │                   │
        ▼               ▼                   ▼

 smtp.gmail.com   mail.gmx.net    smtp.provider.example
```

Thunderbird only knows a single SMTP server.

The relay decides which upstream SMTP server to use.

---

# Requirements

- Docker
- Docker Compose
- Internet access

---

# Project structure

```
postfix-relay/

├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
│
└── config/
    │
    ├── main.cf
    ├── build_maps.sh
    │
    ├── identities/
    │     ├── gmail.conf
    │     ├── gmx.conf
    │     └── yourdomain.conf
    │
    └── secrets/
          ├── gmail.pass
          ├── gmx.pass
          └── yourdomain.pass
```

---

# Installation

Clone the repository.

Build the image.

```bash
docker compose build
```

Start the relay.

```bash
docker compose up -d
```

Check container status.

```bash
docker compose ps
```

Follow the logs.

```bash
docker compose logs -f
```

Stop the relay.

```bash
docker compose down
```

---

# Configuration

Every SMTP provider has one configuration file inside

```
config/identities/
```

Example:

```
gmail.conf
```

```properties
FROM=firstname.lastname@gmail.com,firstname.lastname@googlemail.com

RELAY=smtp.gmail.com
PORT=587

USERNAME=firstname.lastname@gmail.com

PASSWORD_FILE=/config/secrets/gmail.pass
```

Passwords are stored separately.

Example

```
config/secrets/gmail.pass
```

```
YOUR_GOOGLE_APP_PASSWORD
```

---

# Domain wildcard

If a complete domain shall use the same SMTP provider:

```properties
FROM=@yourdomain.com
```

Every sender address belonging to this domain will use the configured relay.

Examples:

```
mail@yourdomain.com

support@yourdomain.com

firstname.lastname@yourdomain.com
```

---

# Multiple sender addresses

Multiple sender addresses can be configured.

Example

```properties
FROM=firstname.lastname@gmail.com,firstname.lastname@googlemail.com
```

---

# Adding another provider

Create

```
config/identities/provider.conf
```

Create its password

```
config/secrets/provider.pass
```

Restart the relay.

```bash
docker compose restart
```

Done.

---

# Thunderbird configuration

Every Thunderbird account uses the same SMTP server.

Server

```
smtp.your.dockerhost.local
```

Port

```
587
```

The relay automatically chooses the correct upstream SMTP server.

---

# Security

Version 1.0 intentionally keeps the relay simple.

Implemented:

- relay only
- no local mailboxes
- no MX support
- sender whitelist
- sender dependent routing
- local network access only

Not implemented:

- SMTP AUTH for clients
- TLS between Thunderbird and relay
- Docker secrets
- DKIM signing

These features are planned for Version 1.1.

---

# Logs

Show logs

```bash
docker compose logs -f
```

---

# Testing

Example

Send a mail using

```
firstname.lastname@gmail.com
```

The log should show

```
relay=smtp.gmail.com
```

Then send another mail using

```
firstname.lastname@gmx.de
```

The log should show

```
relay=mail.gmx.net
```

Finally send

```
support@yourdomain.com
```

The configured SMTP server for

```
@yourdomain.com
```

should be used.

---

# Version

Version 1.0