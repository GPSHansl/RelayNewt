# relaynewt - Postfix Relay
Development Roadmap

This document contains ideas, improvements and future features that are
intentionally **not part of Version 1.0**.

---

# Version 1.1

## Sender-dependent SMTP authentication

Current implementation:

```
relayhost
    │
    ▼
smtp_sasl_password_maps
```

This allows only one username/password per relay host.

Example:

```
firstname@gmail.com
family@gmail.com
```

would both authenticate with the same Gmail account.

### Planned improvement

Investigate and implement

```
smtp_sender_dependent_authentication = yes
```

allowing authentication to be selected by sender address instead of relay
host.

Goal:

```
firstname@gmail.com
    │
    ├── smtp.gmail.com
    └── firstname@gmail.com / password A

family@gmail.com
    │
    ├── smtp.gmail.com
    └── family@gmail.com / password B
```

Status:

- investigate Postfix implementation
- verify compatibility with sender_dependent_relayhost_maps
- update build_maps.sh

Priority:

High

---

## Docker Secrets

Replace

```
PASSWORD_FILE=/config/secrets/...
```

with Docker Secrets.

Benefits

- passwords not stored inside project tree
- better production deployment

Priority

Medium

---

## SMTP AUTH for local clients

Current Version 1.0 trusts only the local network.

Future:

- SMTP AUTH
- roaming clients
- VPN support

Priority

Medium

---

## TLS between Thunderbird and Relay

Current Version 1.0 uses plain SMTP inside the trusted LAN.

Future:

- STARTTLS
- Let's Encrypt
- self-signed certificates

Priority

Medium

---

## Automatic configuration validation

Add checks for

- duplicate relay definitions
- missing password files
- invalid email addresses
- invalid domain wildcards

Priority

Medium

---

## Better logging

Improve startup output.

Examples

```
Loaded identities: 4

Allowed senders: 9

Configured relays: 3
```

Priority

Low

---

## Optional DKIM signing

Useful when sending through own SMTP providers.

Not required when upstream provider already signs outgoing mail.

Priority

Low

---

## Unit tests

Automatically verify

- generated sender_relay
- sender_access
- sasl_passwd

using sample identity files.

Priority

Low

---

# Ideas

## Identity aliases

Instead of

```
PASSWORD_FILE=/config/secrets/gmail.pass
```

use

```
SECRET=gmail
```

The build script automatically resolves

```
/config/secrets/gmail.pass
```

Advantages

- shorter configuration
- fewer duplicated paths

---

## Identity schema version

Support

```
VERSION=1
```

inside identity files to allow future extensions without breaking
compatibility.

---

## Web GUI

Possibly a small management interface.

Out of scope for Version 1.x.

---

# Out of Scope

The following features are intentionally not planned.

- Local mailboxes
- IMAP server
- POP3 server
- MX operation
- Spam filtering
- Virus scanning
- Mailing lists
- Groupware
- Webmail

This project is intended to remain a lightweight SMTP relay only.