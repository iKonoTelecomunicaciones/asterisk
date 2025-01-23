# vim:set ft=dockerfile:

FROM centos:7 AS get_rsp

# Configure the vault.centos.org repository
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Install required packages
RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum -y install \
    git \
    libpcap-devel \
    patch \
    wget && \
    yum clean all && \
    rm -rf /var/cache/yum

# Get the Asterisk source package
COPY asterisk-rsp /

# Copy .env file
COPY .env /

# Execute the get_rsp script
RUN bash get_rsp.sh

# Get sipsak
RUN git clone https://github.com/nils-ohlmeier/sipsak.git

# Set working directory
WORKDIR /sipsak

# Compile sipsak
RUN autoreconf --install && \
    ./configure && \
    make && \
    make install




FROM centos:7

# Metadata
LABEL maintainer="Andrius Kairiukstis <k@andrius.mobi>"

# Environment variables
ENV ASTERISK_VERSION 1.4.24.1
ENV ASTERISK_ADDONS_VERSION 1.4.13

# Copy the get_rsp base image
COPY --from=get_rsp /etc/yum.repos.d/CentOS-* /etc/yum.repos.d
COPY --from=get_rsp /asterisk-${ASTERISK_VERSION} /usr/src/asterisk
COPY --from=get_rsp /usr/local/bin/sipsak /usr/local/bin/sipsak

# Install required packages
RUN yum update -y && \
    yum -y install \
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
    git \
    deltarpm \
    pkgconfig \
    gtk2-devel \
    mysql-devel \
    epel-release.noarch \
    python-devel \
    python2-pip \
    unixODBC-devel && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN echo -e "[irontec] \
    \nname=Irontec RPMs repository \
    \nbaseurl=http://packages.irontec.com/centos/\$releasever/\$basearch/" > /etc/yum.repos.d/irontec.repo && \
    rpm --import http://packages.irontec.com/public.key

# Install extra packages
RUN yum -y install \
    sox \
    libogg \
    libogg-devel \
    vorbis-tools \
    libvorbis-devel \
    cronie \
    mailx \
    ssmtp \
    which \
    libpcap-devel \
    sngrep && \
    yum clean all && \
    rm -rf /var/cache/yum



# Update pip
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | python

# Copy requirements.txt to the container
COPY requirements.txt .

# Install dependencies
RUN pip install -r requirements.txt

# Build Asterisk
COPY build-asterisk.sh /
RUN /build-asterisk.sh

# Expose ports and volumes
EXPOSE 5060/udp 5060/tcp
VOLUME /var/lib/asterisk/sounds /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk

# Copy Entrypoint
COPY docker-entrypoint.sh /

# Set Entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]

# Set working directory
WORKDIR /etc/asterisk

# Start Asterisk
CMD ["/usr/sbin/asterisk", "-vvvdddf", "-T", "-U", "asterisk", "-p"]