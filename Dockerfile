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
# Install files
#
COPY --chmod=755 assets/entrypoint.sh assets/build_maps.sh /
COPY --chmod=644 assets/postfix/main.cf assets/postfix/master.cf /etc/postfix/

#
# SMTP Submission
#
EXPOSE 587

ENTRYPOINT ["/entrypoint.sh"]