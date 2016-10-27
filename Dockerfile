FROM alpine:3.4

MAINTAINER Christoph Zauner <christoph.zauner@nllk.net>


############################################################
# Setup HTTP proxy
#

ENV NO_PROXY_LIST="" \
    PROXY=""

RUN if [ -n "$VAR" ]; then echo "---> SETTING PROXY VARS" \
    && export http_proxy=$PROXY \
    && export HTTP_PROXY=$PROXY \
    && export https_proxy=$PROXY \
    && export HTTPS_PROXY=$PROXY; \
	else echo "---> NOT SETTING PROXY VARS"; fi

#ENV no_proxy=$NO_PROXY_LIST \
#    NO_PROXY=$NO_PROXY_LIST

#
#
############################################################


############################################################
# Install common packages
#

RUN set -x \
    && apk add --update --no-cache \
       bash \
       iputils \
       openssh \
       screen \
       su-exec \
       vim \
       # Busybox wget can not be used with some proxies. Don't ask why....
       wget

#
#
############################################################


############################################################
# Configure supervisord
#

RUN set -x \
    && apk add --update --no-cache supervisor

# Replace default with our custom config.
COPY files/etc/supervisord.conf /etc/
# Dirs have to exist in order for supervisord to log into them.
RUN mkdir /var/log/supervisord_children

#
#
############################################################


############################################################
# Install cntrinfod
#
#

COPY README.md /

ENV CNTRINFOD_VERSION=0.2.6

# Beware when updating the link! The filename is just cosmetic. The ID
# in front of the filename actually decides which content will be downloaded!
RUN wget -nv --no-check-certificate -P /tmp https://github.com/zaunerc/cntrinfod/releases/download/v${CNTRINFOD_VERSION}/cntrinfod-v${CNTRINFOD_VERSION}-x64-libmusl.tar.gz \
    && tar -C / -v -xzf /tmp/cntrinfod-v${CNTRINFOD_VERSION}-x64-libmusl.tar.gz

#
#
############################################################


############################################################
# Configure SSHD & interactive shell sessions
#
#

ENV USER_ADMIN=gopher
ENV GROUP_ADMIN=$USER_ADMIN

RUN set -x \
    && apk add --update --no-cache \
       sudo

# Generate host keys. 
RUN ssh-keygen -A

RUN addgroup $GROUP_ADMIN \
    && adduser -D -h /home/$USER_ADMIN -g "sudo admin" -s /bin/bash -G ${GROUP_ADMIN} ${USER_ADMIN} \
    && addgroup $GROUP_ADMIN wheel \
    && head /dev/urandom | tr -dc A-Za-z0-9 | head -c12 | sed "s/\(.*\)/$USER_ADMIN:\1/" | chpasswd

RUN sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers \
    # Check if substitution was successfull. grep will return a non-zero exit
    # code if there is no match.
    && grep '%wheel ALL=(ALL) NOPASSWD: ALL' /etc/sudoers

COPY files/etc/sudoers.d/env_keep /etc/sudoers.d/env_keep

#
#
############################################################


############################################################
# Install cntrbrowserd
#
#

ENV CNTRBROWSERD_VERSION=0.2.1

# Beware when updating the link! The filename is just cosmetic. The ID
# in front of the filename actually decides which content will be downloaded!
RUN wget -nv --no-check-certificate -P /tmp https://github.com/zaunerc/cntrbrowserd/releases/download/v${CNTRBROWSERD_VERSION}/cntrbrowserd-v${CNTRBROWSERD_VERSION}-x64-libmusl.tar.gz \
    && tar -C / -v -xzf /tmp/cntrbrowserd-v${CNTRBROWSERD_VERSION}-x64-libmusl.tar.gz

#
#
############################################################


############################################################
# Install consul
# 
# As of Sep. 2016 there is no up-to date consul package
# available in the alpine linux package repos.
#
# https://github.com/hashicorp/docker-consul/blob/9a59dc1a87adc164b72ac67bc9e4364a3fc4138d/0.6/Dockerfile
# was used as a template.
#

ENV CONSUL_VERSION=0.6.4

RUN addgroup consul && \
    adduser -S -G consul consul

# Disabled GPG verification because of network problems.
RUN apk add --no-cache ca-certificates gnupg && \
    #gpg --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    # download
    wget -nv https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    wget -nv https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS && \
    #wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig && \
    # verify
    #gpg --batch --verify consul_${CONSUL_VERSION}_SHA256SUMS.sig consul_${CONSUL_VERSION}_SHA256SUMS && \
    grep consul_${CONSUL_VERSION}_linux_amd64.zip consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c && \
    # extract
    unzip -d /bin consul_${CONSUL_VERSION}_linux_amd64.zip && \
    cd /tmp && \
    rm -rf /tmp/build && \
    apk del gnupg && \
    rm -rf /root/.gnupg

# The /consul/data dir is used by Consul to store state. The agent will be started
# with /consul/config as the configuration directory so you can add additional
# config files in that location.
RUN mkdir -p /consul/data && \
    mkdir -p /consul/config && \
    chown -R consul:consul /consul

# Expose the consul data directory as a volume since there's mutable state in there.
#VOLUME /consul/data

# Server RPC is used for communication between Consul clients and servers for internal
# request forwarding.
#EXPOSE 8300

# Serf LAN and WAN (WAN is used only by Consul servers) are used for gossip between
# Consul agents. LAN is within the datacenter and WAN is between just the Consul
# servers in all datacenters.
#EXPOSE 8301 8301/udp 8302 8302/udp

# CLI, HTTP, and DNS (both TCP and UDP) are the primary interfaces that applications
# use to interact with Consul.
#EXPOSE 8400 8500 8600 8600/udp

#
#
############################################################


############################################################
# Clone dotfiles and go-scripts.
#
#

RUN set -x \
    && apk add --update --no-cache \
       git

USER $USER_ADMIN

RUN mkdir ~/repos \
    && cd ~/repos \
    && git clone https://github.com/zaunerc/go-scripts.git \
    && git clone https://github.com/zaunerc/configs.git

# Requires sudo
RUN ~/repos/configs/install.sh

# Requires sudo
RUN ~/repos/go-scripts/dev-setup-scripts/alpine.sh

RUN git config --global user.email "christoph.zauner@NLLK.net" \
    && git config --global user.name "Christoph Zauner"

ENV GOPATH=/home/$USER_ADMIN/gowork

RUN go get github.com/zaunerc/cntrbrowserd \
    && go get github.com/zaunerc/cntrinfod

#
#
############################################################


# 22/ssh: SSHD
# 80/http: cntrbrowserd
# 2020/http: cntrinfod
# 8500/http: consul web interface
# 9001/http: supervisord web interface
#
EXPOSE 22 80 2020 8500 9001 

USER root
CMD ["supervisord"]

