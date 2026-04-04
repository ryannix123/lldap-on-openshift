FROM quay.io/centos/centos:stream10

LABEL org.opencontainers.image.title="OpenLDAP on OpenShift" \
      org.opencontainers.image.description="Self-contained LDAPS authentication service for OpenShift namespaces" \
      org.opencontainers.image.source="https://github.com/ryannix123/openldap-on-openshift" \
      org.opencontainers.image.licenses="Apache-2.0" \
      maintainer="Ryan Nix <ryan.nix@gmail.com>"

# openldap-servers was removed from RHEL/CentOS Stream starting with RHEL 8.
# The LTB (LDAP Tool Box) project maintains OpenLDAP 2.6 RPMs for EL10.
# Package installs under /usr/local/openldap/ — see entrypoint.sh for paths.
RUN curl -fsSL https://ltb-project.org/lib/RPM-GPG-KEY-LTB-project \
      -o /etc/pki/rpm-gpg/RPM-GPG-KEY-LTB-project && \
    printf '[ltb-project]\nname=LTB project packages\nbaseurl=https://ltb-project.org/rpm/openldap26/$releasever/$basearch\nenabled=1\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-LTB-project\n' \
      > /etc/yum.repos.d/ltb-project.repo && \
    dnf install -y openldap-ltb && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# LTB prefix for all OpenLDAP paths
ENV OPENLDAP_PREFIX=/usr/local/openldap

# Remove any package post-install defaults so the entrypoint bootstraps cleanly
RUN rm -rf ${OPENLDAP_PREFIX}/etc/openldap/slapd.d/* \
           ${OPENLDAP_PREFIX}/var/openldap-data/*

# OpenShift assigns an arbitrary UID at runtime; all writable dirs must be
# group-owned by GID 0 (root) with group-write so any UID:0 combo works.
RUN mkdir -p ${OPENLDAP_PREFIX}/var/openldap-data \
             ${OPENLDAP_PREFIX}/etc/openldap/slapd.d \
             ${OPENLDAP_PREFIX}/var/run \
             /etc/openldap/certs && \
    chown -R 1001:0 ${OPENLDAP_PREFIX}/var \
                    ${OPENLDAP_PREFIX}/etc/openldap/slapd.d && \
    chmod -R g=u    ${OPENLDAP_PREFIX}/var \
                    ${OPENLDAP_PREFIX}/etc/openldap && \
    # certs dir is read-only (mounted Secret) — no group-write needed
    chown 1001:0 /etc/openldap/certs && \
    chmod 750    /etc/openldap/certs

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Non-privileged ports — OpenShift restricted SCC won't allow <1024
# The Service maps 389→1389 and 636→1636
EXPOSE 1389 1636

USER 1001

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
