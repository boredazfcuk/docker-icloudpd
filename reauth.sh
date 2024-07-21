#!/bin/ash

run_as() {
   local command_to_run
   command_to_run="${1}"
   if [ "$(id -u)" = 0 ]; then
      su "${user:=user}" -s /bin/ash -c "${command_to_run}"
   else
      /bin/ash -c "${command_to_run}"
   fi
}

user="$(grep "^user=" /config/icloudpd.conf | awk -F= '{print $2}')"
apple_id="$(grep apple_id /config/icloudpd.conf | awk -F= '{print $2}')"
auth_china="$(grep auth_china /config/icloudpd.conf | awk -F= '{print $2}')"
cookie_file="$(echo -n "${apple_id//[^a-z0-9_]/}")"

if [ "${auth_china:=false}" = true ]; then
    auth_domain="cn"
fi

if [ -f "/config/${cookie_file}" ]; then
   rm "/config/${cookie_file}"
fi

if [ -f "/config/${cookie_file}.session" ]; then
   rm "/config/${cookie_file}.session"
fi

run_as "/opt/icloudpd/bin/icloudpd --username ${apple_id} --cookie-directory /config --auth-only --domain ${auth_domain:=com} | tee /tmp/icloudpd/reauth.log"

rm /tmp/icloudpd/reauth.log