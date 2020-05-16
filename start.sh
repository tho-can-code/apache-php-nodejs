#!/bin/bash

shopt -s nocasematch

if [[ "$ENABLE_RPAF_MODULE" =~ ^(true|yes|y|1)$ ]] ; then
    DOCKER_GATEWAY_IP=$(ip route show 0.0.0.0/0 | grep -Eo 'via \S+' | awk '{ print $2 }')
    RPAF_CONF=/etc/apache2/mods-available/rpaf.conf
    sed -i.bak -r -e "s/^(\s*RPAF_ProxyIPs\s*).*$/\1127.0.0.1 $DOCKER_GATEWAY_IP/g" $RPAF_CONF
    if [[ $? != 0 ]]; then
      echo "ERROR: $RPAF_CONF update failed." && exit 1
    elif ! cat "$RPAF_CONF" | grep -F -e "$DOCKER_GATEWAY_IP"; then
      echo "ERROR: $DOCKER_GATEWAY_IP not found in $RPAF_CONF after update" && exit 2
    fi
    a2enmod rpaf
fi

shopt -u nocasematch

# Start supervisord and services
exec /usr/bin/supervisord  -n -c /etc/supervisor/supervisord.conf
