#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   if [ ! -d "/tmp/icloudpd" ]; then mkdir --parents "/tmp/icloudpd"; fi
   if [ -f "/tmp/icloudpd/icloudpd_check_exit_code" ]; then rm "/tmp/icloudpd/icloudpd_check_exit_code"; fi
   if [ -f "/tmp/icloudpd/icloudpd_download_exit_code" ]; then rm "/tmp/icloudpd/icloudpd_download_exit_code"; fi
   echo
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** boredazfcuk/icloudpd container for icloud_photo_downloader started *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** $(realpath "${0}") script version: $(date --reference=$(realpath "${0}") +%Y/%m/%d_%H:%M) *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Python version: $(python3 --version | awk '{print $2}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     icloudpd version: $(pip3 list | grep icloudpd | awk '{print $2}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     pyicloud-ipd version: $(pip3 list | grep pyicloud-ipd | awk '{print $2}')"
   cookie="$(echo -n "${apple_id//[^a-zA-Z0-9_]/}" | tr '[:upper:]' '[:lower:]')"
   if [ -t 0 ] || [ -p /dev/stdin ]; then interactive_session="True"; fi
   if [ "${interactive_only}" ]; then unset interactive_session; fi
   if [ -z "${apple_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID not set - exiting"; sleep 120; exit 1; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Interactive session: ${interactive_session:=False}"
   if [ "${interactive_only}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Interactive only mode set, bypassing 2FA cookie generation"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local user: ${user:=user}:${user_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local group: ${group:=group}:${group_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Force GID: ${force_gid:=False}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     LAN IP Address: ${lan_ip}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID: ${apple_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID password: ${apple_password:=usekeyring}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Authentication Type: ${authentication_type:=2FA}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie path: ${config_dir}/${cookie}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie expiry notification period: ${notification_days:=7}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Download destination directory: /home/${user}/iCloud"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Folder structure: ${folder_structure:={:%Y/%m/%d\}}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Directory permissions: ${directory_permissions:=750}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     File permissions: ${file_permissions:=640}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation interval: ${synchronisation_interval:=43200}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Time zone: ${TZ:=UTC}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Additional command line options: ${command_line_options}"
   if [ "${notification_type}" ] && [ "${interactive_session}" = "False" ]; then
      ConfigureNotifications
   fi
   if [ ! -d "/home/${user}/.local/share/" ]; then mkdir --parents "/home/${user}/.local/share/"; fi
   if [ ! -d "${config_dir}/python_keyring/" ]; then mkdir --parents "${config_dir}/python_keyring/"; fi
   if [ ! -L "/home/${user}/.local/share/python_keyring" ]; then ln --symbolic "${config_dir}/python_keyring/" "/home/${user}/.local/share/"; fi
}

ConfigureNotifications(){
   if [ -z "${prowl_api_key}" ] && [ -z "${pushbullet_api_key}" ] && [ -z "${telegram_token}" ] && [ -z "${webhook_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  ${notification_type} notifications enabled, but API key/token not set - disabling notifications"
      unset notification_type
   else
      if [ "${notification_type}" = "Prowl" ] && [ "${prowl_api_key}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notifications enabled"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Notification period: ${notification_days=7}"
         notification_url="https://api.prowlapp.com/publicapi/add" 
         notification_api_key=${prowl_api_key}
         Notify "startup" "iCloudPD container started" "0" "iCloudPD container now starting for Apple ID ${apple_id}"
      elif  [ "${notification_type}" = "Pushbullet" ] && [ "${pushbullet_api_key}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notifications enabled"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Notification period: ${notification_days=7}"
         notification_url="https://pushbullet.weks.net/publicapi/add"
         notification_api_key=${pushbullet_api_key}
         Notify "startup" "iCloudPD container started" "0" "iCloudPD container now starting for Apple ID ${apple_id}"
      elif [ "${notification_type}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]; then
         notification_url="https://api.telegram.org/bot${telegram_token}/sendMessage"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notifications enabled"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} token ${telegram_token}"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} chat id ${telegram_chat_id}"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notification URL: ${notification_url}"
         telegram_text="$(echo -e "\xE2\x84\xB9 *boredazfcuk/iCloudPD*\niCloud\_Photos\_Downloader container started for Apple ID ${apple_id}")"
         Notify "startup" "${telegram_text}"
      elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
         if [ "${webhook_https}" = "True" ]; then webhook_scheme="https"; else webhook_scheme="http"; fi
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notifications enabled"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} server: ${webhook_server}"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} port: ${webhook_port:=8123}"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} path: ${webhook_path:=/api/webhook/}"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} ID: ${webhook_id}"
         notification_url="${webhook_scheme}://${webhook_server}:${webhook_port}${webhook_path}${webhook_id}"
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notification URL: ${notification_url}"
         webhook_payload="$(echo -e "boredazfcuk/iCloudPD - iCloud\_Photos\_Downloader container started for Apple ID ${apple_id}")"
         Notify "startup" "${webhook_payload}"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') WARINING ${notification_type} notifications enabled, but configured incorrectly - disabling notifications"
         unset notification_type prowl_api_key pushbullet_api_key telegram_token telegram_chat_id webhook_scheme webhook_server webhook_port webhook_id
      fi
      if [ "${download_notifications:=True}" = "True" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Download notifications: Enabled"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Download notifications: Disabled"
         unset download_notifications
      fi
      if [ "${delete_notifications:=True}" = "True" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Delete notifications: Enabled"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Delete notifications: Disabled"
         unset delete_notifications
      fi
   fi
}

CreateGroup(){
   if [ "$(grep -c "^${group}:x:${group_id}:" "/etc/group")" -eq 1 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Group, ${group}:${group_id}, already created"
   else
      if [ "$(grep -c "^${group}:" "/etc/group")" -eq 1 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group name, ${group}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${group_id}:" "/etc/group")" -eq 1 ]; then
         if [ "${force_gid}" = "True" ]; then
            group="$(grep ":x:${group_id}:" /etc/group | awk -F: '{print $1}')"
            echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Group id, ${group_id}, already exists - continuing as force_gid variable has been set. Group name to use: ${group}"
         else
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group id, ${group_id}, already in use - exiting"
            sleep 120
            exit 1
         fi
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Creating group ${group}:${group_id}"
         addgroup -g "${group_id}" "${group}"
      fi
   fi
}

CreateUser(){
   if [ "$(grep -c "^${user}:x:${user_id}:${group_id}" "/etc/passwd")" -eq 1 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User, ${user}:${user_id}, already created"
   else
      if [ "$(grep -c "^${user}:" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User name, ${user}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${user_id}:$" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User id, ${user_id}, already in use - exiting"
         sleep 120
         exit 1
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Creating user ${user}:${user_id}"
         adduser -s /bin/ash -D -G "${group}" -u "${user_id}" "${user}" -h "/home/${user}"
      fi
   fi
}

ConfigurePassword(){
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on config directory, if required"
   find "${config_dir}" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on config directory, if required"
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} +
   if [ "${apple_password}" = "usekeyring" ] && [ ! -f "/home/${user}/.local/share/python_keyring/keyring_pass.cfg" ]; then
      if [ "${interactive_session}" = "True" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Adding password to keyring..."
         su "${user}" -c '/usr/bin/icloud --username "${0}"' -- "${apple_id}"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID password set to 'usekeyring' but keyring file does not exist. Container must be run interactively to add a password to the system keyring - Restart in 5mins"
         sleep 300
         exit 1
      fi
   fi
   if [ "${apple_password}" ]; then
      if [ "${apple_password}" = "usekeyring" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Using password stored in keyring"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Using Apple ID password from variable. This password will be visible in the process list of the host. Please add your password to the system keyring instead"
         sleep 15
      fi
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID password not set - exiting"
      sleep 120
      exit 1
   fi
}

Generate2FACookie(){
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on config directory, if required"
   find "${config_dir}" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on config directory, if required"
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} +
   if [ -f "${config_dir}/${cookie}" ]; then
      mv "${config_dir}/${cookie}" "${config_dir}/${cookie}.bak"
   fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Generate 2FA cookie with password: ${apple_password}"
   if [ "${apple_password}" = "usekeyring" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check for new files using password stored in keyring..."
      su "${user}" -c '/usr/bin/icloudpd --username "${0}" --cookie-directory "${1}" --directory "${2}" --only-print-filenames --recent 0' -- "${apple_id}" "${config_dir}" "/dev/null"
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Checking for new files using insecure password method. Please store password in the iCloud keyring to prevent password leaks"
      su "${user}" -c '/usr/bin/icloudpd --username "${0}" --password "${1}" --cookie-directory "${2}" --directory "${3}" --only-print-filenames --recent 0' -- "${apple_id}" "${apple_password}" "${config_dir}" "/dev/null"
   fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie generated. Sync should now be successful."
   exit 0
}

CheckMount(){
   while [ ! -f "/home/${user}/iCloud/.mounted" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Failsafe file /home/${user}/iCloud/.mounted file is not present. Plese check the host's target volume is mounted - retry in 5 minutes"
      sleep 300
   done
}

SetOwnerAndPermissions(){
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set owner, ${user}, on iCloud directory, if required"
   find "/home/${user}/iCloud" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set group, ${group}, on iCloud directory, if required"
   find "/home/${user}/iCloud" ! -group "${group}" -exec chgrp "${group}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on icloudpd temp directory, if required"
   find "/tmp/icloudpd" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on icloudpd temp directory, if required"
   find "/tmp/icloudpd" ! -group "${group}" -exec chgrp "${group}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on config directory, if required"
   find "${config_dir}" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on config directory, if required"
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on keyring directory, if required"
   find "/home/${user}/.local" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on keyring directory, if required"
   find "/home/${user}/.local" ! -group "${group}" -exec chgrp "${group}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set ${directory_permissions:=755} permissions on iCloud directories, if required"
   find "/home/${user}/iCloud" -type d ! -perm "${directory_permissions}" -exec chmod "${directory_permissions}" '{}' +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set ${file_permissions:=640} permissions on iCloud files, if required"
   find "/home/${user}/iCloud" -type f ! -perm "${file_permissions}" -exec chmod "${file_permissions}" '{}' +
}

CheckWebCookie(){
   if [ -f "${config_dir}/${cookie}" ]; then
      web_cookie_expire_date="$(grep "X_APPLE_WEB_KB" "${config_dir}/${cookie}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie does not exist. Please run container interactively to generate - Retry in 5 minutes"
      sleep 300
   fi
}

Check2FACookie(){
   if [ -f "${config_dir}/${cookie}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie exists, check expiry date"
      if [ "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "${config_dir}/${cookie}")" -eq 1 ]; then
         twofa_expire_date="$(grep "X-APPLE-WEBAUTH-HSA-TRUST" "${config_dir}/${cookie}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
         twofa_expire_seconds="$(date -d "${twofa_expire_date}" '+%s')"
         days_remaining="$(($((twofa_expire_seconds - $(date '+%s'))) / 86400))"
         echo "${days_remaining}" > "${config_dir}/DAYS_REMAINING"
         if [ "${days_remaining}" -gt 0 ]; then valid_twofa_cookie="True"; fi
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Valid two factor authentication cookie found. Days until expiration: ${days_remaining}"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie is not 2FA capable, authentication type may have changed. Please run container interactively to generate - Retry in 5 minutes"
         sleep 300
      fi
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie does not exist. Please run container interactively to generate - Retry in 5 minutes"
      sleep 300
   fi
}

Display2FAExpiry(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie expires: ${twofa_expire_date/ / @ }"
   if [ "${days_remaining}" -lt "${notification_days}" ]; then
      if [ "${syncronisation_time}" -gt "${next_notification_time:=$(date +%s)}" ]; then
         if [ "${days_remaining}" -eq 1 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Final day before two factor authentication cookie expires - Please reinitialise now. This is your last reminder"
            if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet" ]; then
               Notify "cookie expiration" "2FA Cookie Expiriation" "2" "Final day before two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise now. This is your last reminder"
               next_notification_time="$(date +%s -d "+24 hour")"
            elif [ "${notification_type}" = "Telegram" ]; then
               telegram_text="$(echo -e "\xF0\x9F\x9A\xA8 *boredazfcuk/iCloudPD\nFinal day before two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise now. This is your last reminder")"
               Notify "cookie expiration" "${telegram_text}"
               next_notification_time="$(date +%s -d "+24 hour")"
            elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
               webhook_payload="$(echo -e "boredazfcuk/iCloudPD - Final day before two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise now. This is your last reminder")"
               Notify "failure" "${webhook_payload}"
               next_notification_time="$(date +%s -d "+24 hour")"
            fi
         else
            echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Only ${days_remaining} days until two factor authentication cookie expires - Please reinitialise"
            if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet" ]; then
               Notify "cookie expiration" "2FA Cookie Expiration" "1" "Only ${days_remaining} days until two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise"
               next_notification_time="$(date +%s -d "+24 hour")"
            elif [ "${notification_type}" = "Telegram" ]; then
               telegram_text="$(echo -e "\xE2\x9A\xA0 *boredazfcuk/iCloudPD* Only ${days_remaining} days until two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise")"
               Notify "cookie expiration" "${telegram_text}"
               next_notification_time="$(date +%s -d "+24 hour")"
            elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
               webhook_payload="$(echo -e "boredazfcuk/iCloudPD - Only ${days_remaining} days until two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise")"
               Notify "failure" "${webhook_payload}"
               next_notification_time="$(date +%s -d "+24 hour")"
            fi
         fi
      fi
   fi
}

CheckFiles(){
   if [ -f "/tmp/icloudpd/icloudpd_check.log" ]; then rm "/tmp/icloudpd/icloudpd_check.log"; fi
   if [ "${apple_password}" = "usekeyring" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check for new files using password stored in keyring..."
      su "${user}" -c '(/usr/bin/icloudpd --directory "/home/${0}/iCloud" --cookie-directory "${1}" --username "${2}" --folder-structure "${3}" --only-print-filenames 2>&1; echo $? >/tmp/icloudpd/icloud_check_exit_code) | tee /tmp/icloudpd/icloudpd_check.log' -- "${user}" "${config_dir}" "${apple_id}" "${folder_structure}" 
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Checking for new files using insecure password method. Please store password in the iCloud keyring to prevent password leaks"
      su "${user}" -c '(/usr/bin/icloudpd --directory "/home/${0}/iCloud" --cookie-directory "${1}" --username "${2}" --password "${3}" --folder-structure "${4}" --only-print-filenames 2>&1; echo $? >/tmp/icloudpd/icloud_check_exit_code) | tee /tmp/icloudpd/icloudpd_check.log' -- "${user}" "${config_dir}" "${apple_id}" "${apple_password}" "${folder_structure}" 
   fi
   check_exit_code="$(cat /tmp/icloudpd/icloud_check_exit_code)"
   if [ "${check_exit_code}" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Check failed - Exit code: ${check_exit_code}"
      if  [ "${notification_type}" = "Pushbullet" ] && [ "${pushbullet_api_key}" ]; then
         Notify "failure" "iCloudPD container failure" "-2" "iCloudPD failed to download new files for Apple ID: ${apple_id} - Exit code ${check_exit_code}"
      elif [ "${notification_type}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]; then
         telegram_text="$(echo -e "\xF0\x9F\x9A\xA8 *boredazfcuk/iCloudPD*\niCloudPD failed to download new files - for Apple ID: ${apple_id} Exit code ${check_exit_code}")"
         Notify "failure" "${telegram_text}"
      elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
         webhook_payload="$(echo -e "boredazfcuk/iCloudPD - iCloudPD failed to download new files for Apple ID: ${apple_id} Exit code ${check_exit_code}")"
         Notify "failure" "${webhook_payload}"
      fi
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check successful"
      check_files_count="$(grep -c ^ /tmp/icloudpd/icloudpd_check.log)"
      if [ "${check_files_count}" -gt 0 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check detected ${check_files_count} files requiring download. Verifying list accuracy"
         local counter=0
         for double_check_file in $(cat /tmp/icloudpd/icloudpd_check.log); do
            if [ -f "${double_check_file}" ]; then
               sed -i "/${double_check_file//\//\\/}/d" /tmp/icloudpd/icloudpd_check.log
               counter=$((counter + 1))
            fi
         done
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Ignoring ${counter} files which have already been downloaded"
         check_files_count="$(grep -c ^ /tmp/icloudpd/icloudpd_check.log)"
      fi
      if [ "${check_files_count}" -gt 0 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     New files detected: ${check_files_count}"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     No new files detected. Nothing to download"
      fi
   fi
}

DownloadedFilesNotification(){
   local new_files_count new_files_preview telegram_new_files_text
   new_files="$(grep "Downloading /" /tmp/icloudpd/icloudpd_sync.log)"
   new_files_count="$(grep -c "Downloading /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${new_files_count:=0}" -gt 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     New files downloaded: ${new_files_count}"
      if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet}" ]; then
         Notify "downloaded files" "New files detected" "0" "Files downloaded for Apple ID ${apple_id} : ${new_files_count}"
      elif [ "${notification_type}" = "Telegram" ]; then
         new_files_preview="$(echo "${new_files}" | awk '{print $5}' | sed -e "s%/home/${user}/iCloud/%%g" | tail -10)"
         new_files_preview_count="$(echo "${new_files_preview}" | wc -l)"
         telegram_new_files_text="$(echo -e "\xE2\x84\xB9 *boredazfcuk/iCloudPD*\nNew files detected for Apple ID ${apple_id}: ${new_files_count}\nLast ${new_files_preview_count} file names:\n${new_files_preview//_/\\_}")"
         Notify "downloaded files" "${telegram_new_files_text}"
      elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
         new_files_preview="$(echo "${new_files}" | awk '{print $5}' | sed -e "s%/home/${user}/iCloud/%%g" | tail -10)"
         new_files_preview_count="$(echo "${new_files_preview}" | wc -l)"
         webhook_payload="$(echo -e "boredazfcuk/iCloudPD - New files detected for Apple ID ${apple_id}: ${new_files_count} Last ${new_files_preview_count} file names: ${new_files_preview//_/\\_}")"
         Notify "failure" "${webhook_payload}"
      fi
   fi
}

DeletedFilesNotification(){
   local deleted_files deleted_files_count deleted_files_preview telegram_deleted_files_text
   deleted_files="$(grep "Deleting /" /tmp/icloudpd/icloudpd_sync.log)"
   deleted_files_count="$(grep -c "Deleting /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${deleted_files_count:=0}" -gt 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Number of files deleted: ${deleted_files_count}"
      if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet}" ]; then
         Notify "deleted files" "Recently deleted files detected" "0" "Files deleted for Apple ID ${apple_id}: ${deleted_files_count}"
      elif [ "${notification_type}" = "Telegram" ]; then
         deleted_files_preview="$(echo "${deleted_files}" | awk '{print $5}' | sed -e "s%/home/${user}/iCloud/%%g" -e "s%!$%%g" | tail -10)"
         deleted_files_preview_count="$(echo "${deleted_files_preview}" | wc -l)"
         telegram_deleted_files_text="$(echo -e "\xE2\x84\xB9 *boredazfcuk/iCloudPD*\nDeleted files detected for Apple ID: ${apple_id}: ${deleted_files_count}\nLast ${deleted_files_preview_count} file names:\n${deleted_files_preview//_/\\_}")"
         Notify "deleted files" "${telegram_deleted_files_text}"
      elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
         deleted_files_preview="$(echo "${deleted_files}" | awk '{print $5}' | sed -e "s%/home/${user}/iCloud/%%g" -e "s%!$%%g" | tail -10)"
         deleted_files_preview_count="$(echo "${deleted_files_preview}" | wc -l)"
         webhook_payload="$(echo -e "boredazfcuk/iCloudPD - Deleted files detected for Apple ID: ${apple_id}: ${deleted_files_count} Last ${deleted_files_preview_count} file names: ${deleted_files_preview//_/\\_}")"
         Notify "failure" "${webhook_payload}"
      fi
   fi
}

ConvertDownloadedHEIC2JPEG(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Convert HEIC to JPEG..."
   for heic_file in $(echo "${new_files}" | grep ".HEIC" | awk '{print $5}'); do
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Converting ${heic_file} to ${heic_file%.HEIC}.JPG"
      heif-convert "${heic_file}" "${heic_file%.HEIC}.JPG"
   done
}

ConvertAllHEICs(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Convert all HEICs to JPEG, if required..."
   for heic_file in $(find "/home/${user}/iCloud" -type f -name *.HEIC 2>/dev/null); do
      if [ ! -f "${heic_file%.HEIC}.JPG" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Converting ${heic_file} to ${heic_file%.HEIC}.JPG"
         heif-convert "${heic_file}" "${heic_file%.HEIC}.JPG"
      fi
   done
}

Notify(){
   if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sending ${notification_type} ${1} notification"
      curl --silent "${notification_url}"  \
         --form apikey="${notification_api_key}" \
         --form application="boredazfcuk/iCloudPD" \
         --form event="${2}" \
         --form priority="${3}" \
         --form description="${4}" \
         >/dev/null 2>&1
         curl_exit_code=$?
      if [ "${curl_exit_code}" -eq 0 ]; then 
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notification sent successfully for Apple ID ${apple_id}: \"Event: ${1}\" \"Priority ${2}\" \"Message ${3}\""
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    ${notification_type} notification failed for Apple ID ${apple_id}"
         sleep 120
         exit 1
      fi
   elif [ "${notification_type}" = "Telegram" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sending ${notification_type} ${1} notification"
      curl --silent --request POST "${notification_url}" \
         --data chat_id="${telegram_chat_id}" \
         --data parse_mode="markdown" \
         --data text="${2}" \
         >/dev/null 2>&1
         curl_exit_code=$?
      if [ "${curl_exit_code}" -eq 0 ]; then 
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} ${1} notification sent successfully"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    ${notification_type} ${1} notification failed"
         sleep 120
         exit 1
      fi
   elif [ "${notification_type}" = "Webhook" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sending ${notification_type} ${1} notification"
      curl --silent --request POST "${notification_url}" \
         --header 'content-type: application/json' \
         --data "{ \"data\" : \"${2}\" }" \
         >/dev/null 2>&1
         curl_exit_code=$?
      if [ "${curl_exit_code}" -eq 0 ]; then 
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} ${1} notification sent successfully"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    ${notification_type} ${1} notification failed"
         sleep 120
         exit 1
      fi
   fi
}

SyncUser(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sync user ${user}"
   while :; do
      chown -R "${user}":"${group}" "${config_dir}"
      if [ "${authentication_type}" = "2FA" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check 2FA Cookie"
         valid_twofa_cookie=False
         while [ "${valid_twofa_cookie}" = "False" ]; do Check2FACookie; done
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check download directory mounted correctly"
      CheckMount
      CheckFiles
      if [ "${check_exit_code}" -eq 0 ]; then
         if [ "${check_files_count}" -gt 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Starting download of ${check_files_count} new files for user: ${user}"
            syncronisation_time="$(date +%s -d '+15 minutes')"
            if [ "${apple_password}" = "usekeyring" ]; then
               echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Downloading new files using password stored in keyring..."
               su "${user}" -c '(/usr/bin/icloudpd --directory "/home/${0}/iCloud" --cookie-directory "${1}" --username "${2}" --folder-structure "${3}" ${4} 2>&1; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log' -- "${user}" "${config_dir}" "${apple_id}" "${folder_structure}" "${command_line_options}"
            else
               echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Downloading new files using insecure password method. Please store password in the iCloud keyring to prevent password leaks"
               su "${user}" -c '(/usr/bin/icloudpd --directory "/home/${0}/iCloud" --cookie-directory "${1}" --username "${2}" --password "${3}" --folder-structure "${4}" ${5} 2>&1; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log' -- "${user}" "${config_dir}" "${apple_id}" "${apple_password}" "${folder_structure}" "${command_line_options}"
            fi
            download_exit_code="$(cat /tmp/icloudpd/icloudpd_download_exit_code)"
            if [ "${download_exit_code}" -gt 0 ]; then
               echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Error during download - Exit code: ${download_exit_code}"
               if  [ "${notification_type}" = "Pushbullet" ] && [ "${pushbullet_api_key}" ]; then
                  Notify "failure" "iCloudPD container failure" "-2" "iCloudPD failed to download new files for Apple ID ${apple_id} - Exit code ${download_exit_code}"
               elif [ "${notification_type}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]; then
                  telegram_text="$(echo -e "\xF0\x9F\x9A\xA8 *boredazfcuk/iCloudPD*\niCloudPD failed to download new files for Apple ID ${apple_id} - Exit code ${download_exit_code}")"
                  Notify "failure" "${telegram_text}"
               elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
                  webhook_payload="$(echo -e "boredazfcuk/iCloudPD - iCloudPD failed to download new files for Apple ID ${apple_id} - Exit code ${download_exit_code}")"
                  Notify "failure" "${webhook_payload}"
               fi
            else
               if [ "${download_notifications}" ]; then DownloadedFilesNotification; fi
               if [ "${convert_heic_to_jpeg}" ]; then
                  echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Convert HEIC files to JPEG"
                  ConvertDownloadedHEIC2JPEG
               fi
               if [ "${delete_notifications}" ]; then DeletedFilesNotification; fi
               echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation complete for ${user}"
            fi
         fi
      fi
      CheckWebCookie
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Web cookie expires: ${web_cookie_expire_date/ / @ }"
      if [ "${authentication_type}" = "2FA" ]; then Display2FAExpiry; fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Next syncronisation at $(date +%H:%M -d "${synchronisation_interval} seconds")"
      unset check_exit_code check_files_count download_exit_code
      unset new_files
      sleep "${synchronisation_interval}"
   done
}

##### Script #####
Initialise
CreateGroup
CreateUser
ConfigurePassword
if [ "${interactive_session}" = "True" ]; then
   if [ "$1" = "--ConvertAllHEICs" ]; then
      ConvertAllHEICs
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     HEIC to JPG conversion complete"
      exit 0
   elif [ -z "$1" ]; then
      Generate2FACookie
   fi
fi
CheckMount
SetOwnerAndPermissions
SyncUser
