#!/bin/ash

apple_id="$(grep apple_id /config/icloudpd.conf | awk -F= '{print $2}')"
auth_china="$(grep auth_china /config/icloudpd.conf | awk -F= '{print $2}')"

if [ "${auth_china:=false}" = true ]; then
    auth_domain="cn"
fi

/opt/icloudpd_latest/bin/icloudpd --username "${apple_id}" --auth-only --domain "${auth_domain:=com}"