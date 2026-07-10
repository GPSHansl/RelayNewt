# Identity files

Put one `.conf` file per SMTP provider in this directory.

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
- `PORT`: upstream SMTP port
- `USERNAME`: login name for the upstream SMTP server
- `PASSWORD`: password or app password for the upstream SMTP server

Use `FROM=@yourdomain.com` to match an entire domain.

