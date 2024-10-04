# vim:set ft=dockerfile:

FROM centos:7 AS get_rsp
RUN yum -y install subversion patch wget

COPY asterisk-rsp /
RUN bash get_rsp.sh

FROM centos:7

LABEL maintainer="Andrius Kairiukstis <k@andrius.mobi>"

ENV ASTERISK_VERSION 1.4.24.1
ENV ASTERISK_ADDONS_VERSION 1.4.13

COPY --from=get_rsp asterisk-${ASTERISK_VERSION} /usr/src/asterisk

RUN yum -y install \
    cpp \
    gcc \
    gcc-c++ \
    make \
    ncurses \
    ncurses-devel \
    libxml2 \
    libxml2-devel \
    openssl-devel \
    newt-devel \
    libuuid-devel \
    net-snmp-devel \
    xinetd \
    tar \
    libffi-devel \
    sqlite-devel \
    curl \
    bison \
    wget \
    deltarpm \
    pkgconfig \
    gtk2-devel \
    mysql-devel \
    unixODBC-devel

COPY build-asterisk.sh /
RUN /build-asterisk.sh

EXPOSE 5060/udp 5060/tcp
VOLUME /var/lib/asterisk/sounds /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/asterisk", "-vvvdddf", "-T", "-U", "asterisk", "-p"]
#CMD ["tail", "-f", "/dev/null"]