#!/bin/ash

##### Functions #####
Initialise(){
   echo
   save_ifs="${IFS}"
   lan_ip="$(hostname -i)"
   login_counter="0"
   apple_id="$(echo -n ${apple_id} | tr '[:upper:]' '[:lower:]')"
   cookie_file="$(echo -n "${apple_id//[^a-z0-9_]/}")"
   local icloud_dot_com dns_counter
   if [ "${icloud_china}" ]; then
      icloud_domain="icloud.com.cn"
   else
      icloud_domain="icloud.com"
   fi
   case "${synchronisation_interval:=86400}" in
      21600) synchronisation_interval=21600;; # 6 hours
      43200) synchronisation_interval=43200;; # 12 hours
      86400) synchronisation_interval=86400;; # 24 hours
      129600) synchronisation_interval=129600;; # 36 hours
      172800) synchronisation_interval=172800;; # 48 hours
      604800) synchronisation_interval=604800;; # 7 days
      *) synchronisation_interval=86400;; # 24 hours
   esac
   if [ "${synchronisation_delay:=0}" -gt 60 ]; then
      synchronisation_delay=60
   fi
   if [ ! -d "/tmp/icloudpd" ]; then mkdir --parents "/tmp/icloudpd"; fi
   if [ -f "/tmp/icloudpd/icloudpd_check_exit_code" ]; then rm "/tmp/icloudpd/icloudpd_check_exit_code"; fi
   if [ -f "/tmp/icloudpd/icloudpd_download_exit_code" ]; then rm "/tmp/icloudpd/icloudpd_download_exit_code"; fi
   if [ -f "/tmp/icloudpd/icloudpd_check_error" ]; then rm "/tmp/icloudpd/icloudpd_check_error"; fi
   if [ -f "/tmp/icloudpd/icloudpd_download_error" ]; then rm "/tmp/icloudpd/icloudpd_download_error"; fi
   touch "/tmp/icloudpd/icloudpd_check_exit_code"
   touch "/tmp/icloudpd/icloudpd_download_exit_code"
   touch "/tmp/icloudpd/icloudpd_check_error"
   touch "/tmp/icloudpd/icloudpd_download_error"
   LogInfo "***** boredazfcuk/icloudpd container for icloud_photo_downloader started *****"
   LogInfo "***** For support, please go here: https://github.com/boredazfcuk/docker-icloudpd *****"
   LogInfo "***** $(realpath "${0}") date: $(date --reference=$(realpath "${0}") +%Y/%m/%d_%H:%M) *****"
   LogInfo "***** $(realpath "${0}") hash: $(md5sum $(realpath "${0}") | awk '{print $1}') *****"
   LogInfo "$(cat /etc/*-release | grep "^NAME" | sed 's/NAME=//g' | sed 's/"//g') $(cat /etc/*-release | grep "VERSION_ID" | sed 's/VERSION_ID=//g' | sed 's/"//g')"
   LogInfo "Python version: $(python3 --version | awk '{print $2}')"
   LogInfo "icloudpd version: $(pip3 list | grep icloudpd | awk '{print $2}')"
   LogInfo "pyicloud version: $(pip3 list | grep pyicloud | awk '{print $2}')"
   if [ -z "${apple_id}" ]; then
      LogError "Apple ID not set - exiting"
      sleep 120
      exit 1
   fi
   if [ "${apple_password}" ] && [ "${apple_password}" != "usekeyring" ]; then
      LogError "Apple password configured with variable which is no longer supported. Please add password to system keyring - exiting"
      sleep 120
      exit 1
   fi
   if [ "${apple_password}" = "usekeyring" ]; then
      LogWarning "Apple password variable set to 'userkeyring'. This variable can now be removed as it is now the only supported option, so obsolete - continue in 2 minutes"
      sleep 120
   fi
   LogInfo "Running user id: $(id --user)"
   LogInfo "Running group id: $(id --group)"
   LogInfo "Local user: ${user:=user}:${user_id:=1000}"
   LogInfo "Local group: ${group:=group}:${group_id:=1000}"
   LogInfo "Force GID: ${force_gid:=False}"
   LogInfo "LAN IP Address: ${lan_ip}"
   LogInfo "Default gateway: $(ip route | grep default | awk '{print $3}')"
   LogInfo "DNS server: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')"
   icloud_dot_com="$(nslookup -type=a ${icloud_domain} | grep -v "127.0.0.1" | grep Address | tail -1 | awk '{print $2}')"
   while [ -z "${icloud_dot_com}" ]; do
      if [ "${dns_counter:=0}" = 0 ]; then
         LogWarning "Cannot find ${icloud_domain} IP address - retrying"
      fi
      sleep 10
      icloud_dot_com="$(nslookup -type=a ${icloud_domain} | grep -v "127.0.0.1" | grep Address | tail -1 | awk '{print $2}')"
      dns_counter=$((dns_counter+1))
      if [ "${dns_counter}" = 12 ]; then
         LogError "Cannot find ${icloud_domain} IP address. Please check your DNS settings - exiting"
         sleep 120
         exit 1
      fi
   done
   LogInfo "IP address for ${icloud_domain}: ${icloud_dot_com}"
   if [ "$(traceroute -q 1 -w 1 ${icloud_domain} >/dev/null 2>/tmp/icloudpd/icloudpd_tracert.err; echo $?)" = 1 ]; then
      LogError "No route to ${icloud_domain} found. Please check your container's network settings - exiting"
      LogError "Error debug - $(cat /tmp/icloudpd/icloudpd_tracert.err)"
      sleep 120
      exit 1
   else
      LogInfo "Route check to ${icloud_domain} successful"
   fi
   LogInfo "Apple ID: ${apple_id}"
   LogInfo "Authentication Type: ${authentication_type:=2FA}"
   LogInfo "Cookie path: ${config_dir}/${cookie_file}"
   LogInfo "Cookie expiry notification period: ${notification_days:=7}"
   LogInfo "Download destination directory: ${download_path:=/home/${user}/iCloud}"
   LogInfo "Folder structure: ${folder_structure:={:%Y/%m/%d\}}"
   LogInfo "Directory permissions: ${directory_permissions:=750}"
   LogInfo "File permissions: ${file_permissions:=640}"
   if [ "${syncronisation_interval}" ]; then
      LogWarning "The syncronisation_interval variable contained a typo. This has now been corrected to synchronisation_interval. Please update your container. Defaulting to one sync per 24 hour period"
      synchronisation_interval="86400"
   fi
   LogInfo "Synchronisation interval: ${synchronisation_interval}"
   if [ "${synchronisation_interval}" -lt 43200 ]; then
      LogWarning "Setting synchronisation_interval to less than 43200 (12 hours) may cause throttling by Apple."
      LogWarning "If you run into the following error: "
      LogWarning " - private db access disabled for this account. Please wait a few minutes then try again. The remote servers might be trying to throttle requests. (ACCESS_DENIED)"
      LogWarning "then please change your synchronisation_interval to 43200 or greater and switch the container off for 6-12 hours so Apple's throttling expires. Continuing in 2 minutes"
      if [ "${warnings_acknowledged:=False}" = "True" ]; then
         LogInfo "Throttle warning acknowledged"
      else
         sleep 120
      fi
   fi
   LogInfo "Synchronisation delay (minutes): ${synchronisation_delay}"
   LogInfo "Set EXIF date/time: ${set_exif_datetime:=False}"
   LogInfo "Auto delete: ${auto_delete:=False}"
   LogInfo "Photo size: ${photo_size:=original}"
   LogInfo "Single pass mode: ${single_pass:=False}"
   if [ "${single_pass}" = "True" ]; then
      LogInfo "Single pass mode enabled. Disabling download check"
      skip_check="True"
   fi
   LogInfo "Skip download check: ${skip_check:=False}"
   LogInfo "Skip live photos: ${skip_live_photos:=False}"
   if [ "${recent_only}" ]; then
      LogInfo "Number of most recently added photos to download: ${recent_only}"
   else
      LogInfo "Number of most recently added photos to download: Download All Photos"
   fi
   if [ "${photo_album}" ]; then
      LogInfo "Downloading photos from album: ${photo_album}"
   elif [ "${photo_library}" ]; then
      LogInfo "Downloading photos from library: ${photo_library}"
   else
      LogInfo "Downloading photos from album: Download All Photos"
   fi
   if [ "${until_found}" ]; then
      LogInfo "Stop downloading when prexisiting files count is: ${until_found}"
   else
      LogInfo "Stop downloading when prexisiting files count is: Download All Photos"
   fi
   if [ "${skip_live_photos}" = "False" ]; then LogInfo "Live photo size: ${live_photo_size:=original}"; fi
   LogInfo "Skip videos: ${skip_videos:=False}"
   if [ "${command_line_options}" ]; then
      LogWarning "Additional command line options supplied: ${command_line_options}"
      LogWarning "Additional command line options is depreciated. Please specify all options using the dedicated variables"
   fi
   LogInfo "Convert HEIC to JPEG: ${convert_heic_to_jpeg:=False}"
   if [ "${jpeg_path}" ]; then
      LogInfo "converted JPEGs path: ${jpeg_path}"
   fi
   if [ "${delete_accompanying:=False}" = "True" ] && [ -z "${warnings_acknowledged}" ]; then
      LogInfo "Delete accompanying files (.JPG/.HEIC.MOV)"
      LogWarning "This feature deletes files from your local disk. Please use with caution. I am not responsible for any data loss."
      LogWarning "This feature cannot be used if the 'folder_structure' variable is set to 'none' and also, 'set_exif_datetime' must be 'False'"
      LogWarning "These two settings will increase the chances of de-duplication happening, which could result in the wrong files being removed. Continuing in 2 minutes."
      if [ "${warnings_acknowledged:=False}" = "True" ]; then
         LogInfo "File deletion warning accepted"
      else
         sleep 120
      fi
   fi
   LogInfo "JPEG conversion quality: ${jpeg_quality:=90}"
   if [ "${notification_type}" ]; then
      ConfigureNotifications
   fi
   if [ "${icloud_china}" ]; then
      LogInfo "Downloading from: icloud.com.cn"
      LogWarning "Downloading from icloud.com.cn is untested. Please report issues at https://github.com/boredazfcuk/docker-icloudpd/issues"
      sed -i \
         -e "s#apple.com/#apple.com.cn/#" \
         -e "s#icloud.com/#icloud.com.cn/#" \
         -e "s#icloud.com\"#icloud.com.cn\"#" \
         "$(pip show pyicloud | grep "Location" | awk '{print $2}')/pyicloud/base.py"  
      sed -i \
         -e "s#icloud.com/#icloud.com.cn/#" \
         "$(pip show pyicloud | grep "Location" | awk '{print $2}')/pyicloud/services/account.py"
   else
      LogInfo "Downloading from: icloud.com"
      sed -i \
         -e "s#apple.com.cn/#apple.com/#" \
         -e "s#icloud.com.cn/#icloud.com/#" \
         -e "s#icloud.com.cn\"#icloud.com\"#" \
         "$(pip show pyicloud | grep "Location" | awk '{print $2}')/pyicloud/base.py"      
         sed -i \
         -e "s#icloud.com.cn/#icloud.com/#" \
         "$(pip show pyicloud | grep "Location" | awk '{print $2}')/pyicloud/services/account.py"
   fi
   if [ "${trigger_nextlcoudcli_synchronisation}" ]; then
      LogInfo "Nextcloud synchronisation trigger: Enabled"
   else
      LogInfo "Nextcloud synchronisation trigger: Disabled"
   fi
   if [ ! -d "/home/${user}/.local/share/" ]; then
      LogInfo "Creating directory: /home/${user}/.local/share/"
      mkdir --parents "/home/${user}/.local/share/"
   fi
   if [ ! -d "${config_dir}/python_keyring/" ]; then
      LogInfo "Creating directory: ${config_dir}/python_keyring/"
      mkdir --parents "${config_dir}/python_keyring/"
   fi
   if [ ! -L "/home/${user}/.local/share/python_keyring" ]; then
      LogInfo "Creating symbolic link: /home/${user}/.local/share/python_keyring/ to: ${config_dir}/python_keyring/ directory"
      ln --symbolic --force "${config_dir}/python_keyring/" "/home/${user}/.local/share/"
   fi
}

LogInfo(){
   local log_message
   log_message="${1}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${log_message}"
}

LogWarning(){
   local log_message
   log_message="${1}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  ${log_message}"
}

LogError(){
   local log_message
   log_message="${1}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    ${log_message}"
}

ConfigureNotifications(){
   if [ -z "${prowl_api_key}" ] && [ -z "${pushover_token}" ] && [ -z "${telegram_token}" ] && [ -z "${webhook_id}" ] && [ -z "${dingtalk_token}" ] && [ -z "${discord_token}" ] && [ -z "${iyuu_token}" ] && [ -z "${wecom_secret}" ] && [ -z "${gotify_app_token}" ] && [ -z "${bark_device_key}" ]; then
      LogWarning "${notification_type} notifications enabled, but API key/token/secret not set - disabling notifications"
      unset notification_type
   else
      if [ "${notification_title}" ]; then
         notification_title="${notification_title//[^a-zA-Z0-9_ ]/}"
         LogInfo "Cleaned notification title: ${notification_title}"
      else
         LogInfo "Notification title: ${notification_title:=boredazfcuk/iCloudPD}"
      fi
      if [ "${notification_type}" = "Prowl" ] && [ "${prowl_api_key}" ]; then
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} api key: ${prowl_api_key}"
         notification_url="https://api.prowlapp.com/publicapi/add"
      elif [ "${notification_type}" = "Pushover" ] && [ "${pushover_user}" ] && [ "${pushover_token}" ]; then
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} user: ${pushover_user}"
         LogInfo "${notification_type} token: ${pushover_token}"
         if [ "${pushover_sound}" ]; then
            case "${pushover_sound}" in
               pushover|bike|bugle|cashregister|classical|cosmic|falling|gamelan|incoming|intermission|magic|mechanical|pianobar|siren|spacealarm|tugboat|alien|climb|persistent|echo|updown|vibrate|none)
                  LogInfo "${notification_type} sound: ${pushover_sound}"
               ;;
               *)
                  LogInfo "${notification_type} sound not recognised. Using default"
                  unset pushover_sound
            esac
         fi
         notification_url="https://api.pushover.net/1/messages.json"
      elif [ "${notification_type}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]; then
         notification_url="https://api.telegram.org/bot${telegram_token}/sendMessage"
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} token: ${telegram_token}"
         LogInfo "${notification_type} chat id: ${telegram_chat_id}"
         LogInfo "${notification_type} notification URL: ${notification_url}"
         if [ "${telegram_silent_file_notifications}" ]; then telegram_silent_file_notifications="True"; fi
         LogInfo "${notification_type} silent file notifications: ${telegram_silent_file_notifications:=False}"
      elif [ "${notification_type}" = "openhab" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
         if [ "${webhook_https}" = "True" ]; then
            webhook_scheme="https"
         else
            webhook_scheme="http"
         fi
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} server: ${webhook_server}"
         LogInfo "${notification_type} port: ${webhook_port:=8123}"
         LogInfo "${notification_type} path: ${webhook_path:=/rest/items/}"
         LogInfo "${notification_type} ID: ${webhook_id}"
         notification_url="${webhook_scheme}://${webhook_server}:${webhook_port}${webhook_path}${webhook_id}"
         LogInfo "${notification_type} notification URL: ${notification_url}"
      elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]; then
         if [ "${webhook_https}" = "True" ]; then
            webhook_scheme="https"
         else
            webhook_scheme="http"
         fi
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} server: ${webhook_server}"
         LogInfo "${notification_type} port: ${webhook_port:=8123}"
         LogInfo "${notification_type} path: ${webhook_path:=/api/webhook/}"
         LogInfo "${notification_type} ID: ${webhook_id}"
         notification_url="${webhook_scheme}://${webhook_server}:${webhook_port}${webhook_path}${webhook_id}"
         LogInfo "${notification_type} notification URL: ${notification_url}"
         LogInfo "${notification_type} body keyword: ${webhook_body:=data}"
	  elif [ "${notification_type}" = "Discord" ] && [ "${discord_id}" ] && [ "${discord_token}" ]; then
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} Discord ID: ${discord_id}"
         LogInfo "${notification_type} Discord token: ${discord_token}"
         notification_url="https://discord.com/api/webhooks/${discord_id}/${discord_token}"
         LogInfo "${notification_type} notification URL: ${notification_url}"
      elif [ "${notification_type}" = "Dingtalk" ] && [ "${dingtalk_token}" ]; then
         notification_url="https://oapi.dingtalk.com/robot/send?access_token=${dingtalk_token}"
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} token: ${dingtalk_token}"
         LogInfo "${notification_type} notification URL: ${notification_url}"
      elif [ "${notification_type}" = "IYUU" ] && [ "${iyuu_token}" ]; then
         notification_url="http://iyuu.cn/${iyuu_token}.send?"
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} token: ${iyuu_token}"
         LogInfo "${notification_type} notification URL: ${notification_url}"
      elif [ "${notification_type}" = "WeCom" ] && [ "${wecom_id}" ] && [ "${wecom_secret}" ]; then
         wecom_base_url="https://qyapi.weixin.qq.com"
         if [ "${wecom_proxy}" ]; then
            wecom_base_url="${wecom_proxy}"
            LogInfo "${notification_type} notifications proxy enabled : ${wecom_proxy}"
         fi
         wecom_token_url="${wecom_base_url}/cgi-bin/gettoken?corpid=${wecom_id}&corpsecret=${wecom_secret}"
         wecom_token="$(/usr/bin/curl -s -G "${wecom_token_url}" | awk -F\" '{print $10}')"
         wecom_token_expiry="$(date --date='2 hour')"
         notification_url="${wecom_base_url}/cgi-bin/message/send?access_token=${wecom_token}"
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} token: ${wecom_token}"
         LogInfo "${notification_type} token expiry time: $(date -d "${wecom_token_expiry}")"
         LogInfo "${notification_type} notification URL: ${notification_url}"
      elif [ "${notification_type}" = "Gotify" ] && [ "${gotify_app_token}" ] && [ "${gotify_server_url}" ]; then
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} token: ${gotify_app_token}"
         LogInfo "${notification_type} server URL: ${gotify_server_url}"
         notification_url="https://${gotify_server_url}/message?token=${gotify_app_token}"
      elif [ "${notification_type}" = "Bark" ] && [ "${bark_device_key}" ] && [ "${bark_server}" ]; then
         LogInfo "${notification_type} notifications enabled"
         LogInfo "${notification_type} device key: ${bark_device_key}"
         LogInfo "${notification_type} server: ${bark_server}"
         notification_url="http://${bark_server}/push"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') WARINING ${notification_type} notifications enabled, but configured incorrectly - disabling notifications"
         unset notification_type prowl_api_key pushover_user pushover_token telegram_token telegram_chat_id webhook_scheme webhook_server webhook_port webhook_id dingtalk_token discord_id discord_token iyuu_token wecom_id wecom_secret gotify_app_token gotify_server_url bark_device_key bark_server
      fi
      if [ -z "${icloud_china}" ]; then
         Notify "startup" "iCloudPD container started" "0" "iCloudPD container now starting for Apple ID ${apple_id}"
      else
         Notify "startup" "iCloudPD container started" "0" "启动成功，开始同步当前 Apple ID 中的照片"
      fi
      if [ "${download_notifications:=True}" = "True" ]; then
         LogInfo "Download notifications: Enabled"
      else
         LogInfo "Download notifications: Disabled"
         unset download_notifications
      fi
      if [ "${delete_notifications:=True}" = "True" ]; then
         LogInfo "Delete notifications: Enabled"
      else
         LogInfo "Delete notifications: Disabled"
         unset delete_notifications
      fi
   fi
}

CreateGroup(){
   if [ "$(grep -c "^${group}:x:${group_id}:" "/etc/group")" -eq 1 ]; then
      LogInfo "Group, ${group}:${group_id}, already created"
   else
      if [ "$(grep -c "^${group}:" "/etc/group")" -eq 1 ]; then
         LogError "Group name, ${group}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${group_id}:" "/etc/group")" -eq 1 ]; then
         if [ "${force_gid}" = "True" ]; then
            group="$(grep ":x:${group_id}:" /etc/group | awk -F: '{print $1}')"
            LogWarning "Group id, ${group_id}, already in use by the group: ${group} - continuing as force_gid variable has been set. Group name to use: ${group}"
         else
            LogError "Group id, ${group_id}, already in use by the group: ${group} - exiting. If you must to add your user to this pre-existing system group, please set the force_gid variable to True"
            sleep 120
            exit 1
         fi
      else
         LogInfo "Creating group ${group}:${group_id}"
         groupadd --gid "${group_id}" "${group}"
      fi
   fi
}

CreateUser(){
   if [ "$(grep -c "^${user}:x:${user_id}:${group_id}" "/etc/passwd")" -eq 1 ]; then
      LogInfo "User, ${user}:${user_id}, already created"
   else
      if [ "$(grep -c "^${user}:" "/etc/passwd")" -eq 1 ]; then
         LogError "User name, ${user}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${user_id}:$" "/etc/passwd")" -eq 1 ]; then
         LogError "User id, ${user_id}, already in use - exiting"
         sleep 120
         exit 1
      else
         LogInfo "Creating user ${user}:${user_id}"
         useradd --shell /bin/ash --gid "${group_id}" --uid "${user_id}" "${user}" --home-dir "/home/${user}" --badnames
      fi
   fi
}

ListLibraries(){
   LogInfo "Shared libraries available:"
   shared_libraries="$(su "${user}" -c '/usr/bin/icloudpd --username "${0}" --cookie-directory "${1}" --directory "${2}" --list-libraries | sed "1d"' -- "${apple_id}" "${config_dir}" "/dev/null")"
   for library in ${shared_libraries}; do
      LogInfo " - ${library}"
   done
}

DeletePassword(){
   if [ -f "${config_dir}/python_keyring/keyring_pass.cfg" ]; then
      LogInfo "Keyring file ${config_dir}/python_keyring/keyring_pass.cfg exists, but --RemoveKeyring command line switch has been invoked. Removing"
      rm "${config_dir}/python_keyring/keyring_pass.cfg"
   fi
}

ConfigurePassword(){
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Configure password"
   if [ -f "${config_dir}/python_keyring/keyring_pass.cfg" ] && [ "$(grep -c "=" "${config_dir}/python_keyring/keyring_pass.cfg")" -eq 0 ]; then
      LogInfo "Keyring file ${config_dir}/python_keyring/keyring_pass.cfg exists, but does not contain any credentials. Removing"
      rm "${config_dir}/python_keyring/keyring_pass.cfg"
   fi
   if [ ! -f "/home/${user}/.local/share/python_keyring/keyring_pass.cfg" ]; then
      if [ "${initialise_container}" ]; then
         LogInfo "Adding password to keyring file: ${config_dir}/python_keyring/keyring_pass.cfg"
         su "${user}" -c '/usr/bin/icloud --username "${0}"' -- "${apple_id}"
      else
         LogError "Keyring file ${config_dir}/python_keyring/keyring_pass.cfg does not exist"
         LogInfo " - Please add the your password to the system keyring using the --Initialise script command line option"
         LogInfo " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
         LogInfo " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
         LogInfo "Waiting for keyring file to be created..."
         local counter
         counter="${counter:=0}"
         while [ ! -f "/home/${user}/.local/share/python_keyring/keyring_pass.cfg" ]; do
            sleep 5
            counter=$((counter + 1))
            if [ "${counter}" -eq 360 ]; then
               LogInfo "Keyring file has not appeared within 30 minutes. Restarting container..."
               exit 1
            fi
         done
         LogInfo "Keyring file exists, continuing"
      fi
   else
      LogInfo "Using password stored in keyring file: ${config_dir}/python_keyring/keyring_pass.cfg"
   fi
}

GenerateCookie(){
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on config directory, if required"
   find "${config_dir}" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on config directory, if required"
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} +
   if [ -f "${config_dir}/${cookie_file}" ]; then
      mv "${config_dir}/${cookie_file}" "${config_dir}/${cookie_file}.bak"
   fi
   LogInfo "Generate ${authentication_type} cookie using password stored in keyring file"
   su "${user}" -c '/usr/bin/icloudpd --username "${0}" --cookie-directory "${1}" --directory "${2}" --only-print-filenames --recent 0' -- "${apple_id}" "${config_dir}" "/dev/null"
   if [ "${authentication_type}" = "2FA" ]; then
      if [ "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "${config_dir}/${cookie_file}")" -eq 1 ]; then
         LogInfo "Two factor authentication cookie generated. Sync should now be successful"
      else
         LogError "2FA information missing from cookie. Authentication has failed"
         LogError " - Was the correct password entered?"
         LogError " - Was the 2FA code mistyped?"
         LogError " - Can you log into iCloud.com without receiving pop-up notifications?"
         if [ -z "${icloud_china}" ]; then LogError " - Are you based in China? You may need to set the icloud_china variable"; fi
      fi
   else
      LogInfo "Web cookie generated. Sync should now be successful"
   fi
}

CheckMount(){
   LogInfo "Check download directory mounted correctly"
   if [ ! -f "${download_path}/.mounted" ]; then
      LogWarning "Failsafe file ${download_path}/.mounted file is not present. Waiting for failsafe file to be created..."
      local counter
      counter="0"
   fi
   while [ ! -f "${download_path}/.mounted" ]; do
      sleep 5
      counter=$((counter + 1))
      if [ "${counter}" -eq 360 ]; then
         LogInfo "Failsafe file has not appeared within 30 minutes. Restarting container..."
         exit 1
      fi
   done
   LogInfo "Failsafe file ${download_path}/.mounted exists, continuing"
}

SetOwnerAndPermissions(){
   LogInfo "Set owner, ${user}, on iCloud directory, if required"
   find "${download_path}" ! -type l ! -user "${user}" -exec chown "${user}" {} +
   LogInfo "Set group, ${group}, on iCloud directory, if required"
   find "${download_path}" ! -type l ! -group "${group}" -exec chgrp "${group}" {} +
   LogInfo "Correct owner on icloudpd temp directory, if required"
   find "/tmp/icloudpd" ! -user "${user}" -exec chown "${user}" {} +
   LogInfo "Correct group on icloudpd temp directory, if required"
   find "/tmp/icloudpd" ! -group "${group}" -exec chgrp "${group}" {} +
   LogInfo "Correct owner on config directory, if required"
   find "${config_dir}" ! -user "${user}" -exec chown "${user}" {} +
   LogInfo "Correct group on config directory, if required"
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} +
   LogInfo "Correct owner on keyring directory, if required"
   find "/home/${user}/.local" ! -user "${user}" -exec chown "${user}" {} +
   LogInfo "Correct group on keyring directory, if required"
   find "/home/${user}/.local" ! -group "${group}" -exec chgrp "${group}" {} +
   LogInfo "Set ${directory_permissions} permissions on iCloud directories, if required"
   find "${download_path}" -type d ! -perm "${directory_permissions}" -exec chmod "${directory_permissions}" '{}' +
   LogInfo "Set ${file_permissions} permissions on iCloud files, if required"
   find "${download_path}" -type f ! -perm "${file_permissions}" -exec chmod "${file_permissions}" '{}' +
}

CheckWebCookie(){
   if [ -f "${config_dir}/${cookie_file}" ]; then
      web_cookie_expire_date="$(grep "X_APPLE_WEB_KB" "${config_dir}/${cookie_file}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   else
      LogError "Cookie does not exist"
      LogInfo " - Please create your cookie using the --Initialise script command line option"
      LogInfo " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
      LogInfo " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
      LogInfo "Waiting for cookie file to be created..."
      local counter
      counter="${counter:=0}"
      while [ ! -f "${config_dir}/${cookie_file}" ]; do
         sleep 5
         counter=$((counter + 1))
         if [ "${counter}" -eq 360 ]; then
            LogInfo "Cookie file has not appeared within 30 minutes. Restarting container..."
            exit 1
         fi
      done
      LogInfo "Cookie file exists, continuing"
   fi
}

Check2FACookie(){
   if [ -f "${config_dir}/${cookie_file}" ]; then
      LogInfo "Cookie exists, check expiry date"
      if [ "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "${config_dir}/${cookie_file}")" -eq 1 ]; then
         twofa_expire_date="$(grep "X-APPLE-WEBAUTH-HSA-TRUST" "${config_dir}/${cookie_file}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
         twofa_expire_seconds="$(date -d "${twofa_expire_date}" '+%s')"
         days_remaining="$(($((twofa_expire_seconds - $(date '+%s'))) / 86400))"
         echo "${days_remaining}" > "${config_dir}/DAYS_REMAINING"
         if [ "${days_remaining}" -gt 0 ]; then
            valid_twofa_cookie="True"
            LogInfo "Valid two factor authentication cookie found. Days until expiration: ${days_remaining}"
         else
            rm -f "${config_dir}/${cookie_file}"
            LogError "Cookie expired at: ${twofa_expire_date}"
            LogInfo "Expired cookie file has been removed"
            LogInfo " - Please recreate your cookie using the --Initialise script command line option"
            LogInfo " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
            LogInfo " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
            LogInfo "Waiting for cookie file to be created..."
            local counter
            counter="${counter:=0}"
            while [ ! -f "${config_dir}/${cookie_file}" ]; do
               sleep 5
               counter=$((counter + 1))
               if [ "${counter}" -eq 360 ]; then
                  LogInfo "Cookie file has not appeared within 30 minutes. Restarting container..."
                  exit 1
               fi
            done
            LogInfo "Cookie file exists, continuing"
         fi
      else
         LogError "Cookie is not 2FA capable, authentication type may have changed"
         LogInfo " - Please recreate your cookie using the --Initialise script command line option"
         LogInfo " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
         LogInfo " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
         LogInfo "Restarting in 5 minutes..."
         sleep 300
         exit 1
      fi
   else
      LogError "Cookie does not exist"
      LogInfo " - Please create your cookie using the --Initialise script command line option"
      LogInfo " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
      LogInfo " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
      LogInfo "Waiting for cookie file to be created..."
      local counter
      counter="${counter:=0}"
      while [ ! -f "${config_dir}/${cookie_file}" ]; do
         sleep 5
         counter=$((counter + 1))
         if [ "${counter}" -eq 360 ]; then
            LogInfo "Cookie file has not appeared within 30 minutes. Restarting container..."
            exit 1
         fi
      done
      LogInfo "Cookie file exists, continuing"
   fi
}

Display2FAExpiry(){
   local error_message
   LogInfo "Two factor authentication cookie expires: ${twofa_expire_date/ / @ }"
   LogInfo "Days remaining until expiration: ${days_remaining}"
   if [ "${days_remaining}" -le "${notification_days}" ]; then
      if [ "${days_remaining}" -eq 1 ]; then
         cookie_status="cookie expired"
         if [ -z "${icloud_china}" ]; then
            error_message="Final day before two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise now. This is your last reminder"
         else
            error_message="今天是 ${name} 的 Apple ID 两步验证 cookie 到期前的最后一天 - 请立即重新初始化，这是最后的提醒"
         fi
      else
         cookie_status="cookie expiration"
         if [ -z "${icloud_china}" ]; then
            error_message="Only ${days_remaining} days until two factor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise"
         else
            error_message="${days_remaining} 天后 ${name} 的 Apple ID 两步验证将到期 - 请立即重新初始化"
         fi
      fi
      LogWarning "${error_message}"
      if [ "${synchronisation_time:=$(date +%s -d '+15 minutes')}" -gt "${next_notification_time:=$(date +%s)}" ]; then
         Notify "${cookie_status}" "2FA Cookie Expiration" "2" "${error_message}"
         next_notification_time="$(date +%s -d "+24 hour")"
         LogInfo "Next notification not before: $(date +%H:%M:%S -d "${next_notification_time} seconds")"
      fi
   fi
}

CheckFiles(){
   if [ -f "/tmp/icloudpd/icloudpd_check.log" ]; then rm "/tmp/icloudpd/icloudpd_check.log"; fi
   LogInfo "Check for new files using password stored in keyring file"
   LogInfo "Generating list of files in iCloud. This may take a long time if you have a large photo collection. Please be patient. Nothing is being downloaded at this time"
   >/tmp/icloudpd/icloudpd_check_error
   su "${user}" -c '(/usr/bin/icloudpd --directory "${0}" --cookie-directory "${1}" --username "${2}" --folder-structure "${3}" --only-print-filenames 2>/tmp/icloudpd/icloudpd_check_error; echo $? >/tmp/icloudpd/icloudpd_check_exit_code) | tee /tmp/icloudpd/icloudpd_check.log' -- "${download_path}" "${config_dir}" "${apple_id}" "${folder_structure}" 
   check_exit_code="$(cat /tmp/icloudpd/icloudpd_check_exit_code)"
   if [ "${check_exit_code}" -ne 0 ]; then
      LogError "Failed check for new files files"
      LogError " - Can you log into iCloud.com without receiving pop-up notifications?"
      LogError "Error debugging info:"
      LogError "$(cat /tmp/icloudpd/icloudpd_check_error)"
      LogError "***** Please report problems here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
      if [ -z "${icloud_china}" ]; then
         Notify "failure" "iCloudPD container failure" "0" "iCloudPD failed check for new files for Apple ID: ${apple_id}"
      else
         syn_end_time="$(date '+%H:%M:%S')"
         syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
         Notify "failure" "iCloudPD container failure" "0" "检查 iCloud 图库新照片失败，将在 ${syn_next_time} 再次尝试"
      fi
   else
      LogInfo "Check successful"
      check_files_count="$(grep -c ^ /tmp/icloudpd/icloudpd_check.log)"
      if [ "${check_files_count}" -gt 0 ]; then
         LogInfo "New files detected: ${check_files_count}"
      else
         LogInfo "No new files detected. Nothing to download"
      fi
   fi
   login_counter=$((login_counter + 1))
}

DownloadedFilesNotification(){
   local new_files_count new_files_preview new_files_text
   new_files="$(grep "Downloading /" /tmp/icloudpd/icloudpd_sync.log)"
   new_files_count="$(grep -c "Downloading /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${new_files_count:=0}" -gt 0 ]; then
      LogInfo "New files downloaded: ${new_files_count}"
      new_files_preview="$(echo "${new_files}" | awk '{print $5}' | sed -e "s%${download_path}/%%g" | head -10)"
      new_files_preview_count="$(echo "${new_files_preview}" | wc -l)"
      if [ -z "${icloud_china}" ]; then
         new_files_text="Files downloaded for Apple ID ${apple_id}: ${new_files_count}"
         Notify "downloaded files" "New files detected" "0" "${new_files_text}" "${new_files_preview_count}" "downloaded" "${new_files_preview}"
      else
         new_files_text="iCloud 图库同步完成，新增 ${new_files_count} 张照片"
         Notify "downloaded files" "New files detected" "0" "${new_files_text}" "${new_files_preview_count}" "下载" "${new_files_preview}"
      fi
      if [ "${trigger_nextlcoudcli_synchronisation}" ]; then
         touch "${download_path}/.nextcloud_sync"
      fi
   fi
}

DeletedFilesNotification(){
   local deleted_files deleted_files_count deleted_files_preview deleted_files_text
   deleted_files="$(grep "Deleting /" /tmp/icloudpd/icloudpd_sync.log)"
   deleted_files_count="$(grep -c "Deleting /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${deleted_files_count:=0}" -gt 0 ]; then
      LogInfo "Number of files deleted: ${deleted_files_count}"
      deleted_files_preview="$(echo "${deleted_files}" | awk '{print $5}' | sed -e "s%${download_path}/%%g" -e "s%!$%%g" | tail -10)"
      deleted_files_preview_count="$(echo "${deleted_files_preview}" | wc -l)"
      if [ -z "${icloud_china}" ]; then
         deleted_files_text="Files deleted for Apple ID ${apple_id}: ${deleted_files_count}"
         Notify "deleted files" "Recently deleted files detected" "0" "${deleted_files_text}" "${deleted_files_preview_count}" "deleted" "${deleted_files_preview}"
      else
         deleted_files_text="iCloud 图库同步完成，删除 ${deleted_files_count} 张照片"
         Notify "deleted files" "Recently deleted files detected" "0" "${deleted_files_text}" "${deleted_files_preview_count}" "删除" "${deleted_files_preview}"
      fi
      if [ "${trigger_nextlcoudcli_synchronisation}" ]; then
         touch "${download_path}/.nextcloud_sync"
      fi
   fi
}

ConvertDownloadedHEIC2JPEG(){
   IFS="$(echo -en "\n\b")"
   LogInfo "Convert HEIC to JPEG..."
   for heic_file in $(echo "$(grep "Downloading /" /tmp/icloudpd/icloudpd_sync.log)" | grep ".HEIC" | awk '{print $5}'); do
      if [ ! -f "${heic_file}" ]; then
         LogWarning "HEIC file ${heic_file} does not exist. It may exist in 'Recently Deleted' so has been removed post download"
      else
         jpeg_file="${heic_file%.HEIC}.JPG"
         if [ "${jpeg_path}" ]; then
            jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
            mkdir --parents "$(dirname "${jpeg_file}")"
         fi
         LogInfo "Converting ${heic_file} to ${jpeg_file}"
         convert -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
         heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
         LogInfo "Timestamp of HEIC file: ${heic_date}"
         touch --reference="${heic_file}" "${jpeg_file}"
         LogInfo "Setting timestamp of ${jpeg_file} to ${heic_date}"
         LogInfo "Correct owner and group of ${jpeg_file} to ${user}:${group}"
         chown "${user}:${group}" ${jpeg_file}
      fi
   done
   IFS="${save_ifs}"
}

SynologyPhotosAppFix(){
   # Works for onestix. Do not obsolete
   IFS="$(echo -en "\n\b")"
   LogInfo "Fixing Synology Photos App import issue..."
   for heic_file in $(echo "$(grep "Downloading /" /tmp/icloudpd/icloudpd_sync.log)" | grep ".HEIC" | awk '{print $5}'); do
      LogInfo "Create empty date/time reference file ${heic_file%.HEIC}.TMP"
      su "${user}" -c 'touch --reference="${0}" "${1}"' -- "${heic_file}" "${heic_file%.HEIC}.TMP"
      LogInfo "Set time stamp for ${heic_file} to current: $(date)"
      su "${user}" -c 'touch "${0}"' -- "${heic_file}"
      LogInfo "Set time stamp for ${heic_file} to original: $(date -r "${heic_file%.HEIC}.TMP" +"%a %b %e %T %Y")"
      su "${user}" -c 'touch --reference="${0}" "${1}"' -- "${heic_file%.HEIC}.TMP" "${heic_file}"
      LogInfo "Removing temporary file ${heic_file%.HEIC}.TMP"
      if [ -z "${persist_temp_files}" ]; then
         rm "${heic_file%.HEIC}.TMP"
      fi
   done
   IFS="${save_ifs}"
}

ConvertAllHEICs(){
   IFS="$(echo -en "\n\b")"
   LogInfo "Convert all HEICs to JPEG, if required..."
   for heic_file in $(find "${download_path}" -type f -name *.HEIC 2>/dev/null); do
      LogInfo "HEIC file found: ${heic_file}"
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]; then
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
      fi
      if [ ! -f "${jpeg_file}" ]; then
         LogInfo "Converting ${heic_file} to ${jpeg_file}"
         convert -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
         heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
         LogInfo "Timestamp of HEIC file: ${heic_date}"
         touch --reference="${heic_file}" "${jpeg_file}"
         LogInfo "Setting timestamp of ${jpeg_file} to ${heic_date}"
         LogInfo "Correct owner and group of ${jpeg_file} to ${user}:${group}"
         chown "${user}:${group}" "${jpeg_file}"
      fi
   done
   IFS="${save_ifs}"
}

ForceConvertAllHEICs(){
   IFS="$(echo -en "\n\b")"
   LogWarning "Force convert all HEICs to JPEG. This could result in dataloss if JPG files have been edited on disk"
   LogInfo "Waiting for 2mins before progressing. Please stop the container now, if this is not what you want to do..."
   sleep 120
   for heic_file in $(find "${download_path}" -type f -name *.HEIC 2>/dev/null); do
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]; then
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
      fi
      LogInfo "Converting ${heic_file} to ${jpeg_file}"
      rm "${jpeg_file}"
      convert -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
      heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
      LogInfo "Timestamp of HEIC file: ${heic_date}"
      touch --reference="${heic_file}" "${jpeg_file}"
      LogInfo "Setting timestamp of ${jpeg_file} to ${heic_date}"
      LogInfo "Correct owner and group of ${jpeg_file} to ${user}:${group}"
      chown "${user}:${group}" "${jpeg_file}"
   done
   IFS="${save_ifs}"
}

ForceConvertAllmntHEICs(){
   IFS="$(echo -en "\n\b")"
   LogWarning "Force convert all HEICs in /mnt directory to JPEG. This could result in dataloss if JPG files have been edited on disk"
   LogInfo "Waiting for 2mins before progressing. Please stop the container now, if this is not what you want to do..."
   sleep 120
   for heic_file in $(find "/mnt" -type f -name *.HEIC 2>/dev/null); do
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]; then
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
      fi
      LogInfo "Converting ${heic_file} to ${jpeg_file}"
      rm "${jpeg_file}"
      convert -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
      heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
      LogInfo "Timestamp of HEIC file: ${heic_date}"
      touch --reference="${heic_file}" "${jpeg_file}"
      LogInfo "Setting timestamp of ${jpeg_file} to ${heic_date}"
      LogInfo "Correct owner and group of ${jpeg_file} to ${user}:${group}"
      chown "${user}:${group}" "${jpeg_file}"
   done
   IFS="${save_ifs}"
}

CorrectJPEGTimestamps(){
   IFS="$(echo -en "\n\b")"
   LogInfo "Check and correct converted HEIC timestamps"
   for heic_file in $(find "${download_path}" -type f -name *.HEIC 2>/dev/null); do
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]; then
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
      fi
      heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
      LogInfo "Timestamp of HEIC file: ${heic_date}"
      if [ -f "${jpeg_file}" ]; then
         LogInfo "JPEG file found: ${jpeg_file}"
         jpeg_date="$(date -r "${jpeg_file}" +"%a %b %e %T %Y")"
         LogInfo "Timestamp of JPEG file: ${jpeg_date}"
         if [ "${heic_date}" != "${jpeg_date}" ]; then
            LogInfo "Setting timestamp of ${jpeg_file} to ${heic_date}"
            touch --reference="${heic_file}" "${jpeg_file}"
         else
            LogInfo "Time stamps match. Adjustment not required"
         fi
      fi
   done
   IFS="${save_ifs}"
}

RemoveRecentlyDeletedAccompanyingFiles(){
   IFS="$(echo -en "\n\b")"
   LogInfo "Deleting 'Recently Deleted' accompanying files (.JPG/_HEVC.MOV)..."
   for heic_file in $(echo "$(grep "Deleting /" /tmp/icloudpd/icloudpd_sync.log)" | grep ".HEIC" | awk '{print $5}'); do
      heic_file_clean="${heic_file/!/}"
      jpeg_file_clean="${heic_file_clean%.HEIC}.JPG"
      if [ "${jpeg_path}" ]; then
         jpeg_file_clean="${jpeg_file_clean/${download_path}/${jpeg_path}}"
      fi
      if [ -f "${jpeg_file_clean}" ]; then
         LogInfo "Deleting ${jpeg_file_clean}"
         rm -f "${jpeg_file_clean}"
      fi
      if [ -f "${heic_file_clean%.HEIC}_HEVC.MOV" ]; then
         LogInfo "Deleting ${heic_file_clean%.HEIC}_HEVC.MOV"
         rm -f "${heic_file_clean%.HEIC}_HEVC.MOV"
      fi
   done
   LogInfo "Deleting 'Recently Deleted' accompanying files complete"
   IFS="${save_ifs}"
}

RemoveEmptyDirectories(){
   LogInfo "Deleting empty directories from ${download_path}..."
   find "${download_path}" -type d -empty -delete
   LogInfo "Deleting empty directories complete"
   if [ "${jpeg_path}" ]; then
      LogInfo "Deleting empty directories from ${jpeg_path}..."
      find "${jpeg_path}" -type d -empty -delete
      LogInfo "Deleting empty directories complete"
   fi
}

Notify(){
   local notification_classification notification_event notification_prority notification_message notification_result notification_files_preview_count notification_files_preview_type notification_files_preview_text
   notification_classification="${1}"
   notification_event="${2}"
   notification_prority="${3}"
   notification_message="${4}"
   notification_files_preview_count="${5}"
   notification_files_preview_type="${6}"
   notification_files_preview_text="${7}"

   if [ "${notification_classification}" = "startup" ];then
      notification_icon="\xE2\x96\xB6"
      # 启动成功通知封面/Image for Startup success
      thumb_media_id="$media_id_startup"
   elif [ "${notification_classification}" = "downloaded files" ]; then
      notification_icon="\xE2\x8F\xAC"
      # 下载通知封面/Image for downloaded files
      thumb_media_id="$media_id_download"
   elif [ "${notification_classification}" = "cookie expiration" ]; then
      notification_icon="\xF0\x9F\x9A\xA9"
      # cookie即将过期通知封面/Image for cookie expiration
      thumb_media_id="$media_id_expiration"
   elif [ "${notification_classification}" = "deleted files" ]; then
      notification_icon="\xE2\x9D\x8C"
      # 删除文件通知封面/Image for deleted files
      thumb_media_id="$media_id_delete"
   elif [ "${notification_classification}" = "failure" ] || [ "${notification_classification}" = "cookie expired" ]; then
      notification_icon="\xF0\x9F\x9A\xA8"
      # 同步失败、cookiey已过期通知封面/Image for cookie expired or failure
      thumb_media_id="$media_id_warning"
   fi
   if [ "${notification_type}" ]; then LogInfo "Sending ${notification_type} ${notification_classification} notification"; fi
   if [ "${notification_type}" = "Prowl" ]; then
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "${notification_url}"  \
         --form apikey="${prowl_api_key}" \
         --form application="${notification_title}" \
         --form event="${notification_event}" \
         --form priority="${notification_prority}" \
         --form description="${notification_message}")"
   elif [ "${notification_type}" = "Pushover" ]; then
      if [ "${notification_prority}" = "2" ]; then notification_prority=1; fi
      if [ "${notification_files_preview_count}" ]; then
         pushover_text="$(echo -e "${notification_icon} ${notification_event}\n${notification_message}\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\n${notification_files_preview_text}")"
      else
         pushover_text="$(echo -e "${notification_icon} ${notification_event}\n${notification_message}")"
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "${notification_url}"  \
         --form-string "user=${pushover_user}" \
         --form-string "token=${pushover_token}" \
         --form-string "title=${notification_title}" \
         --form-string "sound=${pushover_sound}" \
         --form-string "priority=${notification_prority}" \
         --form-string "message=${pushover_text}")"
   elif [ "${notification_type}" = "Telegram" ]; then
      if [ "${notification_files_preview_count}" ]; then
         telegram_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message//_/\\_}\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\n${notification_files_preview_text//_/\\_}")"
      else
         telegram_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message//_/\\_}")"
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
         --data chat_id="${telegram_chat_id}" \
         --data parse_mode="markdown" \
         --data disable_notification="${telegram_disable_notification:=False}" \
         --data text="${telegram_text}")"
         unset telegram_disable_notification
   elif [ "${notification_type}" = "openhab" ]; then
      webhook_payload="$(echo -e "${notification_title} - ${notification_message}")"
      notification_result="$(curl -X 'PUT' --silent --output /dev/null --write-out "%{http_code}" "${notification_url}" \
         --header 'content-type: text/plain' \
         --data "${webhook_payload}")"
   elif [ "${notification_type}" = "Webhook" ]; then
      webhook_payload="$(echo -e "${notification_title} - ${notification_message}")"
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "${notification_url}" \
         --header 'content-type: application/json' \
         --data "{ \"${webhook_body}\" : \"${webhook_payload}\" }")"
   elif [ "${notification_type}" = "Discord" ]; then
      if [ "${notification_files_preview_count}" ]; then
         discord_text="${notification_message}\\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\\n${notification_files_preview_text//$'\n'/'\n'}"
      else
         discord_text="$(echo -e "${notification_message}")"
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
            --header 'content-type: application/json' \
            --data "{ \"username\" : \"${notification_title}\" , \"avatar_url\" : \"https://raw.githubusercontent.com/Womabre/-unraid-docker-templates/master/images/photos_icon_large.png\" , \"embeds\" : [ { \"author\" : { \"name\" : \"${notification_event}\" } , \"color\" : 2061822 , \"description\": \"${discord_text}\" } ] }")"
   elif [ "${notification_type}" = "Dingtalk" ]; then
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
         --header 'Content-Type: application/json' \
         --data "{'msgtype': 'markdown','markdown': {'title':'${notification_title}','text':'## ${notification_title}\n${notification_message}'}}")"
   elif [ "${notification_type}" = "IYUU" ]; then
      if [ "${notification_files_preview_count}" ]; then
         iyuu_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\n${notification_files_preview_text//_/\\_}")"
      else
         iyuu_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}")"
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
         --data text="${notification_title}" \
         --data desp="${iyuu_text}")"
   elif [ "${notification_type}" = "WeCom" ]; then
      if [ "$(date +'%s')" -ge "$(date +'%s' -d "${wecom_token_expiry}")" ]; then
         unset wecom_token
      fi
      if [ -z "${wecom_token}" ]; then
         LogWarning "${notification_type} token has expired. Retrieving new one"
         wecom_token="$(/usr/bin/curl -s -G "${wecom_token_url}" | awk -F\" '{print $10}')"
         wecom_token_expiry="$(date --date='2 hour')"
         notification_url="${wecom_base_url}/cgi-bin/message/send?access_token=${wecom_token}"
         LogInfo "${notification_type} token: ${wecom_token}"
         LogInfo "${notification_type} token expiry time: $(date -d "${wecom_token_expiry}")"
         LogInfo "${notification_type} notification URL: ${notification_url}"
      fi
      # 结束时间、下次同步时间
      syn_end_time="$(date '+%H:%M:%S')"
      syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
      if [ "${notification_files_preview_count}" ]; then
         if [ -z "${icloud_china}" ]; then
            wecom_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\n${notification_files_preview_text//_/\\_}")"
         else
            notification_files_preview_text="${notification_files_preview_text//$'\n'/'<br/>'}"
            wecom_text="$(echo -e "<font style="line-height:1.5"><center><b><big><big>同步日志</big></big></b></font></center><center><b>${notification_message}</b></center><center>···················  <small>最近 ${notification_files_preview_count} 条${notification_files_preview_type}记录如下</small>  ····················</center><code><small>${notification_files_preview_text}</small></code><center>···················  <small>下次同步时间为 ${syn_next_time}</small>  ··················</center>")"
         fi
      else
         if [ -z "${icloud_china}" ]; then
            wecom_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}")"
         else
            wecom_text="$(echo -e "${notification_message}")"
         fi
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --data-ascii "{\"touser\":\"${touser}\",\"msgtype\":\"mpnews\",\"agentid\":\"${agentid}\",\"mpnews\":{\"articles\":[{\"title\":\"${notification_title} 照片同步 - ${name}\",\"thumb_media_id\":\"${thumb_media_id}\",\"author\":\"${syn_end_time}\",\"content_source_url\":\"${content_source_url}\",\"content\":\"${wecom_text}\",\"digest\":\"${notification_message}\"}]},\"safe\":\"0\",\"enable_id_trans\":\"0\",\"enable_duplicate_check\":\"0\",\"duplicate_check_interval\":\"1800\"}" --url "${notification_url}")"
   elif [ "${notification_type}" = "Gotify" ]; then
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "${notification_url}"  \
         -F "title=${notification_title}" \
         -F "message=${notification_message}")"
   elif [ "${notification_type}" = "Bark" ]; then
      if [ "${notification_files_preview_count}" ]; then
         bark_text="$(echo -e "${notification_icon} ${notification_message} Most recent ${notification_files_preview_count} ${notification_files_preview_type} files: ${notification_files_preview_text//_/\\_}")"
      else
         bark_text="$(echo -e "${notification_icon} ${notification_message}")"
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "http://${bark_server}/push" \
         -H 'Content-Type: application/json; charset=utf-8' \
         -d "{ \"device_key\": \"${bark_device_key}\", \"title\": \"${notification_title}\", \"body\": \"${bark_text}\", \"category\": \"category\" }")"
   fi
   if [ "${notification_type}" ]; then
      if [ "${notification_result:0:1}" -eq 2 ]; then
         LogInfo "${notification_type} ${notification_classification} notification sent successfully"
      else
         LogError "${notification_type} ${notification_classification} notification failed with status code: ${notification_result}"
         LogError "***** Please report problems here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
         sleep 120
         exit 1
      fi
   fi
}

CommandLineBuilder(){
   command_line="--directory ${download_path} --cookie-directory ${config_dir} --folder-structure ${folder_structure} --username ${apple_id}"
   if [ "${photo_size}" != "original"  ]; then
      command_line="${command_line} --size ${photo_size}"
   fi
   if [ "${set_exif_datetime}" != "False" ]; then
      command_line="${command_line} --set-exif-datetime"
   fi
   if [ "${auto_delete}" != "False" ]; then
      command_line="${command_line} --auto-delete"
   fi
   if [ "${skip_live_photos}" = "False" ]; then
      if [ "${live_photo_size}" != "original" ]; then
         command_line="${command_line} --live-photo-size ${live_photo_size}"
      fi
   else
      command_line="${command_line} --skip-live-photos"
   fi
   if [ "${skip_videos}" != "False" ]; then
      command_line="${command_line} --skip-videos"
   fi
   if [ "${photo_album}" ]; then
      command_line="${command_line} --album ${photo_album}"
   elif [ "${photo_library}" ]; then
      command_line="${command_line} --library ${photo_library}"
   fi
   if [ "${until_found}" ]; then
      command_line="${command_line} --until-found ${until_found}"
   fi
   if [ "${recent_only}" ]; then
      command_line="${command_line} --recent ${recent_only}"
   fi
}

SyncUser(){
   LogInfo "Sync user ${user}"
   if [ "${synchronisation_delay}" -ne 0 ]; then
      LogInfo "Delay for ${synchronisation_delay} minutes"
      sleep "${synchronisation_delay}m"
   fi
   while :; do
      synchronisation_start_time="$(date +'%s')"
      LogInfo "Synchronisation starting at $(date +%H:%M:%S -d "@${synchronisation_start_time}")"
      chown -R "${user}":"${group}" "${config_dir}"
      if [ "${authentication_type}" = "2FA" ]; then
         LogInfo "Check 2FA Cookie"
         valid_twofa_cookie=False
         while [ "${valid_twofa_cookie}" = "False" ]; do Check2FACookie; done
      fi
      CheckMount
      if [ "${skip_check}" = "False" ]; then
         CheckFiles
      else
         check_exit_code=0
         check_files_count=1
      fi
      if [ "${check_exit_code}" -eq 0 ]; then
         if [ "${check_files_count}" -gt 0 ]; then
            LogInfo "Starting download of new files for user: ${user}"
            synchronisation_time="$(date +%s -d '+15 minutes')"
            LogInfo "Downloading new files using password stored in keyring file..."
            LogInfo "iCloudPD launch command: /usr/bin/icloudpd ${command_line} ${command_line_options} 2>/tmp/icloudpd/icloudpd_download_error"
            >/tmp/icloudpd/icloudpd_download_error
            su "${user}" -c '(/usr/bin/icloudpd ${0} ${1} 2>/tmp/icloudpd/icloudpd_download_error; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log' -- "${command_line}" "${command_line_options}"
            download_exit_code="$(cat /tmp/icloudpd/icloudpd_download_exit_code)"
            if [ "${download_exit_code}" -gt 0 ]; then
               LogError "Failed to download new files"
               LogError " - Can you log into iCloud.com without receiving pop-up notifications?"
               LogError "Error debugging info:"
               LogError "$(cat /tmp/icloudpd/icloudpd_download_error)"
               LogError "***** Please report problems here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
               if [ -z "${icloud_china}" ]; then
                  Notify "failure" "iCloudPD container failure" "1" "iCloudPD failed to download new files for Apple ID ${apple_id}"
               else
                  # 结束时间、下次同步时间
                  syn_end_time="$(date '+%H:%M:%S')"
                  syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
                  Notify "failure" "iCloudPD container failure" "1" "从 iCloud 图库下载新照片失败，将在 ${syn_next_time} 再次尝试"
               fi
            else
               if [ "${download_notifications}" ]; then DownloadedFilesNotification; fi
               if [ "${synology_photos_app_fix}" ]; then SynologyPhotosAppFix; fi
               if [ "${convert_heic_to_jpeg}" != "False" ]; then
                  LogInfo "Convert HEIC files to JPEG"
                  ConvertDownloadedHEIC2JPEG
               fi
               if [ "${delete_notifications}" ]; then DeletedFilesNotification; fi
               if [ "${delete_accompanying}" = "True" ] && [ "${folder_structure}" != "none" ] && [ "${set_exif_datetime}" = "False" ]; then
                  RemoveRecentlyDeletedAccompanyingFiles
               fi
               if [ "${delete_empty_directories}" = "True" ] && [ "${folder_structure}" != "none" ]; then
                  RemoveEmptyDirectories
               fi
               SetOwnerAndPermissions
               LogInfo "Synchronisation complete for ${user}"
            fi
            login_counter=$((login_counter + 1))
         fi
      fi
      CheckWebCookie
      LogInfo "Web cookie expires: ${web_cookie_expire_date/ / @ }"
      if [ "${authentication_type}" = "2FA" ]; then Display2FAExpiry; fi
      LogInfo "iCloud login counter = ${login_counter}"
      synchronisation_end_time="$(date +'%s')"
      LogInfo "Synchronisation ended at $(date +%H:%M:%S -d "@${synchronisation_end_time}")"
      LogInfo "Total time taken: $(date +%H:%M:%S -u -d @$((synchronisation_end_time - synchronisation_start_time)))"
      if [ "${single_pass:=False}" = "True" ]; then
         LogInfo "Single Pass mode set, exiting"
         exit 0
      else
         sleep_time="$((synchronisation_interval - synchronisation_end_time + synchronisation_start_time))"
         LogInfo "Next synchronisation at $(date +%H:%M:%S -d "${sleep_time} seconds")"
         unset check_exit_code check_files_count download_exit_code
         unset new_files
         sleep "${sleep_time}"
      fi
   done
}

SanitiseLaunchParameters(){
   if [ "${script_launch_parameters}" ]; then
      case "$(echo ${script_launch_parameters} | tr [:upper:] [:lower:])" in
         "--initialise"|"--initialize"|"--init"|"--removekeyring"|"--convertallheics"|"--forceconvertallheics"|"--forceconvertallmntheics"|"--correctjpegtimestamps")
            LogInfo "Script launch parameters: ${script_launch_parameters}"
         ;;
         *)
            LogWarning "Ignoring invalid launch parameter specified: ${script_launch_parameters}"
            LogWarning "Please do not specify the above parameter when launching the container. Continuing in 2 minutes"
            sleep 120
            unset script_launch_parameters
         ;;
      esac
   fi
}

##### Script #####
script_launch_parameters="${1}"
case  "$(echo ${script_launch_parameters} | tr [:upper:] [:lower:])" in
   "--initialise"|"--initialize"|"--init")
      initialise_container="True"
    ;;
   "--removekeyring")
      delete_password="True"
    ;;
   "--convertallheics")
      convert_all_heics="True"
   ;;
   "--forceconvertallheics")
      force_convert_all_heics="True"
   ;;
   "--forceconvertallmntheics")
      force_convert_all_mnt_heics="True"
   ;;
   "--correctjpegtimestamps")
      correct_jpeg_time_stamps="True"
   ;;
   *)
   ;;
esac
Initialise
SanitiseLaunchParameters
CreateGroup
CreateUser
#ListLibraries
SetOwnerAndPermissions
if [ "${delete_password}" ]; then
   DeletePassword
   exit 0
fi
ConfigurePassword
if [ "${initialise_container}" ]; then
   GenerateCookie
   exit 0
elif [ "${convert_all_heics}" ]; then
   ConvertAllHEICs
   SetOwnerAndPermissions
   LogInfo "HEIC to JPG conversion complete"
   exit 0
elif [ "${force_convert_all_heics}" ]; then
   ForceConvertAllHEICs
   SetOwnerAndPermissions
   LogInfo "Forced HEIC to JPG conversion complete"
   exit 0
elif [ "${force_convert_all_mnt_heics}" ]; then
   ForceConvertAllmntHEICs
   SetOwnerAndPermissions
   LogInfo "Forced HEIC to JPG conversion complete"
   exit 0
elif [ "${correct_jpeg_time_stamps}" ]; then
   LogInfo "Correcting timestamps for JPEG files in ${download_path}"
   CorrectJPEGTimestamps
   LogInfo "JPEG timestamp correction complete"
   exit 0
fi
CheckMount
SetOwnerAndPermissions
CommandLineBuilder
SyncUser
