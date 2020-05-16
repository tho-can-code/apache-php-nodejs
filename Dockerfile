FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-utils \
    supervisor \
    curl \
    unzip \
    gcc \
    g++ \
    make \
    build-essential \
    cron \
    # Install git
    git \
    # Install apache
    apache2 \
    apache2-dev \
    # Install php 7.2
    php7.2-fpm \
    php7.2-cli \
    php7.2-json \
    php7.2-curl \
    php7.2-fpm \
    php7.2-gd \
    php7.2-ldap \
    php7.2-mbstring \
    php7.2-mysql \
    php7.2-soap \
    php7.2-sqlite3 \
    php7.2-xml \
    php7.2-zip \
    php7.2-intl \
    php-imagick \
    # Install tools
    openssl \
    nano \
    graphicsmagick \
    imagemagick \
    ghostscript \
    mysql-client \
    iputils-ping \
    locales \
    sqlite3 \
    ca-certificates \
    collectd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Build and install rpaf (reverse proxy add forward module for Apache)
RUN mkdir -p /usr/local/rpaf
COPY rpaf/mod_rpaf-stable.zip /usr/local/rpaf
RUN cd /usr/local/rpaf && unzip mod_rpaf-stable.zip
RUN cd /usr/local/rpaf/mod_rpaf-stable && make && make install
ADD rpaf/rpaf.load /etc/apache2/mods-available
ADD rpaf/rpaf.conf /etc/apache2/mods-available

# Set locales
RUN locale-gen en_US.UTF-8

# Configure PHP
COPY php.ini /etc/php/7.2/fpm/php.ini
COPY www.conf /etc/php/7.2/fpm/pool.d/www.conf

# Configure Apache
RUN rm -rf /etc/apache2/apache2.conf
COPY apache2.conf /etc/apache2/apache2.conf
RUN a2enmod rewrite expires
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
RUN a2enconf servername
RUN a2enconf php7.2-fpm
RUN a2enmod actions proxy proxy_fcgi setenvif rpaf remoteip

# Supervisor
RUN mkdir -p /run/php/
COPY supervisord/conf.d/ /etc/supervisor/conf.d/

# Install nodejs 10.x
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt install -y nodejs
RUN apt install -y yarn

# Install CloudWatch Logs Agent
RUN curl -o amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
RUN dpkg -i -E amazon-cloudwatch-agent.deb
RUN usermod -aG adm cwagent
ENV RUN_IN_CONTAINER="True"
RUN rm -rf amazon-cloudwatch-agent.deb
RUN rm -rf /tmp/* && \
    rm -rf /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard && \
    rm -rf /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl && \
    rm -rf /opt/aws/amazon-cloudwatch-agent/bin/config-downloader
