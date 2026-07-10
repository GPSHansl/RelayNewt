# relaynewt - Postfix Relay

relaynewt is a minimal Postfix SMTP relay for home networks and small internal setups. It accepts mail from trusted local clients and routes outgoing messages to different SMTP providers based on the sender address.

Typical mappings look like this:

- `firstname.lastname@gmail.com` -> `smtp.gmail.com`
- `firstname.lastname@googlemail.com` -> `smtp.gmail.com`
- `firstname.lastname@gmx.de` -> `mail.gmx.net`
- `anything@yourdomain.com` -> your domain provider

No local mailboxes are created, no mail is received from the Internet, and no MX records are required.

## Features

- Relay-only SMTP server
- Sender-dependent relayhost selection
- Multiple SMTP providers
- Multiple sender addresses per identity
- Domain wildcard support, for example `@yourdomain.com`
- Configuration stored in plain text identity files
- Docker Compose based deployment
- Debian Bookworm base image

## Project Layout

```text
.
├── Dockerfile
├── docker-compose_example.yml
├── LICENSE
├── PLANS.md
├── README.md
├── assets/
│   ├── build_maps.sh
│   ├── entrypoint.sh
│   └── postfix/
│       ├── main.cf
│       └── master.cf
├── config/
│   └── identities/
│       └── README.md
└── test/
    ├── config.json.example
    └── test-relaynewt.ps1
```

## Requirements

- Docker
- Docker Compose
- Internet access

## Quick Start

1. Review the identity files in `config/identities/` and adjust them for your providers.
2. Build the image.

```bash
docker compose -f docker-compose_example.yml build
```

3. Start the relay.

```bash
docker compose -f docker-compose_example.yml up -d
```

4. Check the container status.

```bash
docker compose -f docker-compose_example.yml ps
```

5. Follow the logs.

```bash
docker compose -f docker-compose_example.yml logs -f
```

6. Stop the relay.

```bash
docker compose -f docker-compose_example.yml down
```

## Configuration

Each SMTP provider is defined by one file in `config/identities/`. The runtime reads that directory and generates the Postfix lookup tables during container startup.

Example:

```properties
FROM=firstname.lastname@gmail.com,firstname.lastname@googlemail.com
RELAY=smtp.gmail.com
PORT=587

USERNAME=firstname.lastname@googlemail.com
PASSWORD=your-app-password
```

Supported fields:

- `FROM`: one sender address or a comma-separated list of sender addresses
- `RELAY`: upstream SMTP host
- `PORT`: upstream SMTP port, usually `587`
- `USERNAME`: login name for the upstream SMTP server
- `PASSWORD`: password or app password for the upstream SMTP server

Domain wildcards are supported by prefixing the domain with `@`:

```properties
FROM=@yourdomain.com
```

That entry matches every sender address ending in `@yourdomain.com`.

To add another provider, create a new `.conf` file in `config/identities/`, fill in the fields above, and restart the container.

## Testing

The `test/` folder contains a small PowerShell-based SMTP test client.

Copy `test/test-relaynewt-config.json.example` to `test/test-relaynewt-config.json`, adjust the host, port, and sender/recipient pairs, then run:

```powershell
.\test\test-relaynewt.ps1
```

The script expects the relay to be reachable on the configured SMTP host and port.

## Notes

- The container exposes SMTP submission on port `587`.
- Postfix is configured from the files in `assets/postfix/`.
- `assets/entrypoint.sh` validates the configuration and generates the lookup tables at startup.