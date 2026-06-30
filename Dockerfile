#
# relaynewt Postfix Relay
# Version 1.0
#

FROM debian:bookworm-slim

LABEL maintainer="GPSHansl"
LABEL description="Minimal sender-dependent Postfix relay"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        postfix \
        libsasl2-modules \
        ca-certificates \
        bash && \
    rm -rf /var/lib/apt/lists/*

#
# Install entrypoint
#

COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

#
# SMTP Submission
#

EXPOSE 587

ENTRYPOINT ["/entrypoint.sh"]