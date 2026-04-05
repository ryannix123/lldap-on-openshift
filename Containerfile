FROM docker.io/lldap/lldap:stable

LABEL org.opencontainers.image.title="lldap on OpenShift" \
      org.opencontainers.image.description="Lightweight LDAP authentication service for OpenShift namespaces" \
      org.opencontainers.image.source="https://github.com/ryannix123/lldap-on-openshift" \
      org.opencontainers.image.licenses="Apache-2.0" \
      maintainer="Ryan Nix <ryan.nix@gmail.com>"

# OpenShift assigns an arbitrary UID at runtime with GID 0.
# 1. Pre-set group-write on /app at build time so runtime chown of /app succeeds.
# 2. Strip all chown/chmod calls from the bootstrap script — /data is a PVC
#    mount owned by the cluster and cannot be chowned at runtime under
#    the restricted SCC.
USER root
RUN chown -R 1000:0 /app && \
    chmod -R g=u /app && \
    sed -i '/chown/d;/chmod/d' /app/bootstrap.sh

USER 1000

EXPOSE 3890 6360 17170