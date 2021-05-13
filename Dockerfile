FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt -y install software-properties-common

# Microsoft ODBC Driver for SQL Server
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y --allow-unauthenticated msodbcsql17
RUN ACCEPT_EULA=Y apt-get install -y --allow-unauthenticated mssql-tools
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

# For unixODBC development headers
RUN apt-get install -y unixodbc-dev

RUN add-apt-repository ppa:ondrej/php

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
    # Install php 7.4
    php7.4-fpm \
    php7.4-dev \
    php7.4-cli \
    php7.4-json \
    php7.4-curl \
    php7.4-gd \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-mysql \
    php7.4-soap \
    php7.4-sqlite3 \
    php7.4-xml \
    php7.4-zip \
    php7.4-intl \
    php7.4-redis \
    php-imagick \
    php-pear \
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
    redis-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN pecl config-set php_ini /etc/php/7.4/fpm/php.ini
RUN pecl install sqlsrv
RUN pecl install pdo_sqlsrv
RUN printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/7.4/mods-available/sqlsrv.ini
RUN printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/7.4/mods-available/pdo_sqlsrv.ini
RUN phpenmod -v 7.4 sqlsrv pdo_sqlsrv
RUN service php7.4-fpm restart

RUN a2dismod mpm_event
RUN a2enmod mpm_prefork
RUN service apache2 restart

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
COPY php.ini /etc/php/7.4/fpm/php.ini
COPY www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Configure Apache
RUN rm -rf /etc/apache2/apache2.conf
COPY apache2.conf /etc/apache2/apache2.conf
RUN a2enmod rewrite expires headers
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
RUN a2enconf servername
RUN a2enconf php7.4-fpm
RUN a2enmod actions proxy proxy_fcgi setenvif rpaf remoteip
RUN a2dismod reqtimeout
RUN service apache2 restart

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
