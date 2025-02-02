#!/bin/ash

##### Functions #####
initialise_script()
{
   
   log_info "***** boredazfcuk/icloudpd container v1.0.$(cat /opt/build_version.txt) started *****"
   log_info "***** For support, please go here: https://github.com/boredazfcuk/docker-icloudpd *****"
   log_info "$(cat /etc/*-release | grep "^NAME" | cut -d= -f2 | sed 's/"//g') $(cat /etc/*-release | grep "VERSION_ID" | cut -d= -f2 | sed 's/"//g')"
   log_info "Python version: $(cat /tmp/icloudpd/python_version)"
   log_info "icloud-photos-downloader version: $(cat /tmp/icloudpd/icloudpd_version)"
   log_info "Loading configuration from: ${config_file}"
   source "${config_file}"
   save_ifs="${IFS}"
   lan_ip="$(hostname -i)"
   login_counter=0
   apple_id="$(echo -n "${apple_id}" | tr '[:upper:]' '[:lower:]')"
   cookie_file="$(echo -n "${apple_id//[^a-z0-9_]/}")"

   local icloud_dot_com dns_counter
   if [ "${icloud_china:=false}" = true ]
   then
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
   if [ "${synchronisation_delay:=0}" -gt 60 ]
   then
      synchronisation_delay=60
   fi
   log_debug "Running user id: $(id --user)"
   log_debug "Running group id: $(id --group)"
   if [ "${debug_logging}" = true ]
   then
      log_debug "Local user: ${user:0:2}********:${user_id}"
      log_debug "Local group: ${group:0:2}********:${group_id}"
   else
      log_info "Local user: ${user}:${user_id}"
      log_info "Local group: ${group}:${group_id}"
   fi
   log_debug "Force GID: ${force_gid}"
   log_debug "LAN IP Address: ${lan_ip}"
   log_debug "Default gateway: $(ip route | grep default | awk '{print $3}')"
   log_debug "DNS server: $(grep nameserver /etc/resolv.conf | awk '{print $2}')"
   icloud_dot_com="$(nslookup -type=a ${icloud_domain} | grep -v "127.0.0.1" | grep Address | tail -1 | awk '{print $2}')"
   while [ -z "${icloud_dot_com}" ]
   do
      if [ "${dns_counter:=0}" = 0 ]
      then
         log_warning "Cannot find ${icloud_domain} IP address - retrying"
      fi
      sleep 10
      icloud_dot_com="$(nslookup -type=a ${icloud_domain} | grep -v "127.0.0.1" | grep Address | tail -1 | awk '{print $2}')"
      dns_counter=$((dns_counter+1))
      if [ "${dns_counter}" = 12 ]
      then
         log_error "Cannot find ${icloud_domain} IP address. Please check your DNS/Firewall settings - exiting"
         sleep 120
         exit 1
      fi
   done
   log_debug "IP address for ${icloud_domain}: ${icloud_dot_com}"
   if [ "${debug_logging}" = true ]
   then
      log_info "Debug logging: Enabled"
      log_level="debug"
   else
      log_info "Debug logging: Disabled"
      log_level="info"
   fi
   apple_id_prefix="${apple_id%%@*}"
   apple_id_suffix="${apple_id##*@}"
   apple_id_domain="${apple_id_suffix%%.*}"
   apple_id_tld="${apple_id##*.}"
   apple_id_censored="${apple_id_prefix:0:1}******${apple_id_prefix:0-1}@${apple_id_domain:0:1}******.${apple_id_tld}"
   log_info "Apple ID: ${apple_id_censored}"
   cookie_file_censored="$(echo -n "${apple_id_censored//[^a-z0-9_*]/}")"
   log_info "Cookie path: /config/${cookie_file_censored}"
   log_info "Cookie expiry notification period: ${notification_days}"
   log_info "Download destination directory: ${download_path}"
   log_info "Folder structure: ${folder_structure}"
   log_debug "Directory permissions: ${directory_permissions}"
   log_debug "File permissions: ${file_permissions}"
   log_info "Keep Unicode: ${keep_unicode}"
   log_info "Live Photo MOV Filename Policy: ${live_photo_mov_filename_policy}"
   log_info "File Match Policy: ${file_match_policy}"
   log_info "Synchronisation interval: ${synchronisation_interval}"
   log_info "Synchronisation delay (minutes): ${synchronisation_delay}"
   log_info "Set EXIF date/time: ${set_exif_datetime}"
   log_info "Auto delete: ${auto_delete}"
   log_info "Delete after download: ${delete_after_download}"
   if [ "${keep_icloud_recent_only}" = true ]
   then
      log_info "Keep iCloud recent : Enabled"
      log_info "Keep iCloud recent days: ${keep_icloud_recent_days}"
   fi
   log_info "Delete empty directories: ${delete_empty_directories}"
   log_info "Photo size: ${photo_size}"
   log_info "Align RAW: ${align_raw}"
   log_info "Single pass mode: ${single_pass}"
   if [ "${single_pass}" = true ]
   then
      log_debug "Single pass mode enabled. Disabling download check"
      skip_check=true
   fi
   log_info "Skip download check: ${skip_check}"
   log_info "Skip live photos: ${skip_live_photos}"
   if [ "${recent_only}" ]
   then
      log_info "Number of most recently added photos to download: ${recent_only}"
   else
      log_info "Number of most recently added photos to download: Download All Photos"
   fi
   if [ "${photo_album}" ]
   then
      log_info "Downloading photos from album(s): ${photo_album}"
   elif [ "${photo_library}" ]
   then
      log_info "Downloading photos from library: ${photo_library}"
   else
      log_info "Downloading photos from: Download All Photos"
   fi
   if [ "${until_found}" ]
   then
      log_info "Stop downloading when prexisiting files count is: ${until_found}"
   else
      log_info "Stop downloading when prexisiting files count is: Download All Photos"
   fi
   if [ "${skip_live_photos}" = false ]
   then
      log_info "Live photo size: ${live_photo_size}"
   fi
   log_info "Skip videos: ${skip_videos}"
   log_info "Convert HEIC to JPEG: ${convert_heic_to_jpeg}"
   if [ "${convert_heic_to_jpeg}" = true ]
   then
      log_debug "JPEG conversion quality: ${jpeg_quality}"
   fi
   if [ "${jpeg_path}" ]
   then
      log_info "Converted JPEGs path: ${jpeg_path}"
   fi
   if [ "${sideways_copy_videos}" = true ]
   then
      log_debug "Sideways copy videos mode: ${sideways_copy_videos_mode}"
   fi
   if [ "${video_path}" ]
   then
      log_info "Sideways copied videos path: ${video_path}"
   fi
   if [ "${delete_accompanying}" = true ]
   then
      log_info "Delete accompanying files (.JPG/.HEIC.MOV)"
   fi
   if [ "${notification_type}" ]
   then
      configure_notifications
   fi
   log_info "Downloading from: ${icloud_domain}"
   if [ "${icloud_china}" = true ]
   then
      if [ "${auth_china}" = true ]
      then
         auth_domain="cn"
      fi
   fi
   if [ "${fake_user_agent}" = true ]
   then
      log_info "User agent impersonation for curl: Enabled"
      curl_user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edge/122.0.0.0"
   else
      log_debug "User agent impersonation for curl: Disabled"
   fi
   log_info "Authentication domain: ${auth_domain:=com}"
   if [ "${nextcloud_upload}" = true ]
   then
      log_info "Nextcloud upload: Enabled"
      nextcloud_url_scheme="${nextcloud_url%//*}//"
      nextcloud_url_suffix="${nextcloud_url##*//}"
      nextcloud_url_domain="${nextcloud_url_suffix%%/*}"
      nextcloud_url_tld="${nextcloud_url_domain#*.}"
      nextcloud_url_webroot="${nextcloud_url_suffix#*/}"
      nextcloud_url_censored="${nextcloud_url_domain:0:1}********.${nextcloud_url_tld}/${nextcloud_url_webroot%/}${nextcloud_target_dir%/}/"
      nextcloud_url_censored="${nextcloud_url_censored//\/\///}"
      log_debug "Nextcloud username: ${nextcloud_username:0:1}********${nextcloud_username:0-1}"
      log_debug "Nextcloud target directory: ${nextcloud_target_dir}"
      log_debug "Nextcloud destination URL: ${nextcloud_url_scheme}${nextcloud_url_censored}"
   else
      log_debug "Nextcloud upload: Disabled"
   fi
   if [ "${synology_ignore_path}" = true ]
   then
      log_info "Ignore Synology extended attribute directories: Enabled"
      ignore_path="*/@eaDir*"
   else
      log_debug "Ignore Synology extended attribute directories: Disabled"
      ignore_path=""
   fi

   source /opt/icloudpd/bin/activate
   log_debug "Activated Python virtual environment for icloudpd"
}

log_info()
{
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${1}"
}

log_info_n()
{
   echo -n "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${1}... "
}

log_warning()
{
   echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  ${1}"
}

log_error()
{
   echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    ${1}"
}

log_debug()
{
   if [ "${debug_logging}" = true ]
   then
      echo "$(date '+%Y-%m-%d %H:%M:%S') DEBUG    ${1}"
   fi
}

run_as()
{
   if [ "$(id -u)" = 0 ]
   then
      su "${user}" -s /bin/ash -c "${1}"
   else
      /bin/ash -c "${command_to_run}"
   fi
}

clean_notification_title()
{
   if [ "${notification_title}" ]
   then
      notification_title="${notification_title//[^a-zA-Z0-9_ ]/}"
      log_debug "Cleaned notification title: ${notification_title}"
   else
      log_debug "Notification title: ${notification_title:=boredazfcuk/iCloudPD}"
   fi
}

configure_notifications()
{
   if [ -z "${prowl_api_key}" ] && [ -z "${pushover_token}" ] && [ -z "${telegram_token}" ] && [ -z "${webhook_id}" ] && [ -z "${dingtalk_token}" ] && [ -z "${discord_token}" ] && [ -z "${iyuu_token}" ] && [ -z "${wecom_secret}" ] && [ -z "${gotify_app_token}" ] && [ -z "${bark_device_key}" ] && [ -z "${msmtp_pass}" ]
   then
      log_warning "${notification_type} notifications enabled, but API key/token/secret not set - disabling notifications"
      unset notification_type
   else
      if [ "${notification_type}" = "Prowl" ] && [ "${prowl_api_key}" ]
      then
         log_info "${notification_type} notifications enabled"
         clean_notification_title
         log_debug "${notification_type} api key: ${prowl_api_key:0:2}********${prowl_api_key:0-2}"
         notification_url="https://api.prowlapp.com/publicapi/add"
         log_debug "${notification_type} notification URL: ${notification_url}"
      elif [ "${notification_type}" = "Pushover" ] && [ "${pushover_user}" ] && [ "${pushover_token}" ]
      then
         log_info "${notification_type} notifications enabled"
         clean_notification_title
         log_debug "${notification_type} user: ${pushover_user:0:2}********${pushover_user:0-2}"
         log_debug "${notification_type} token: ${pushover_token:0:2}********${pushover_token:0-2}"
         if [ "${pushover_sound}" ]
         then
            case "${pushover_sound}" in
               pushover|bike|bugle|cashregister|classical|cosmic|falling|gamelan|incoming|intermission|magic|mechanical|pianobar|siren|spacealarm|tugboat|alien|climb|persistent|echo|updown|vibrate|none)
                  log_debug "${notification_type} sound: ${pushover_sound}"
               ;;
               *)
                  log_debug "${notification_type} sound not recognised. Using default"
                  unset pushover_sound
            esac
         fi
         notification_url="https://api.pushover.net/1/messages.json"
         log_debug "${notification_type} notification URL: ${notification_url}"
      elif [ "${notification_type}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]
      then
         if [ "${telegram_http}" = true ]
         then
            telegram_protocol="http"
         else
            telegram_protocol="https"
         fi
         if [ "${telegram_server}" ]
         then
            telegram_base_url="${telegram_protocol}://${telegram_server}/bot${telegram_token}"
         else
            telegram_base_url="${telegram_protocol}://api.telegram.org/bot${telegram_token}"
         fi
         notification_url="${telegram_base_url}/sendMessage"
         log_info "${notification_type} notifications enabled"
         clean_notification_title
         log_debug "${notification_type} token: ${telegram_token:0:2}********${telegram_token:0-2}"
         log_debug "${notification_type} chat id: ${telegram_chat_id:0:2}********${telegram_chat_id:0-2}"
         log_debug "${notification_type} polling: ${telegram_polling}"
         log_debug "${notification_type} uses HTTP: ${telegram_http}"
         if [ "${telegram_server}" ]
         then
            log_debug "${notification_type} base URL: ${telegram_protocol}://${telegram_server}/bot${telegram_token:0:2}********${telegram_token:0-2}"
         else
            log_debug "${notification_type} base URL: ${telegram_protocol}://api.telegram.org/bot${telegram_token:0:2}********${telegram_token:0-2}"

         fi
         ##################
         log_debug "${notification_type} notification URL: ${telegram_protocol}://api.telegram.org/bot${telegram_token:0:2}********${telegram_token:0-2}/sendMessage"
         if [ "${script_launch_parameters}" ]
         then
            telegram_polling="false"
         fi
         if [ "${telegram_polling}" = true ]
         then
            if [ "$(cat /tmp/icloudpd/bot_check)" = true ]
            then
               if [ "${telegram_server}" ]
               then
                  log_debug "Checking ${telegram_server} for updates"
               else
                  log_debug "Checking api.telegram.org for updates"
               fi
               telegram_update_id_offset_file="/config/telegram_update_id.num"
               telegram_update_id_offset="$(head -1 ${telegram_update_id_offset_file})"
               log_info "Latest update id: ${telegram_update_id_offset}"
            else
               telegram_polling=false
            fi
         fi
         if [ "${telegram_silent_file_notifications}" ]
         then
            telegram_silent_file_notifications=true
         fi
         log_debug "${notification_type} silent file notifications: ${telegram_silent_file_notifications:=false}"
      elif [ "${notification_type}" = "openhab" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]
      then
         if [ "${webhook_https}" = true ]
         then
            webhook_scheme="https"
         else
            webhook_scheme="http"
         fi
         log_info "${notification_type} notifications enabled"
         notification_url="${webhook_scheme}://${webhook_server}:${webhook_port}${webhook_path}${webhook_id}"
         log_debug "${notification_type} server: ${webhook_server}"
         log_debug "${notification_type} port: ${webhook_port:=8123}"
         log_debug "${notification_type} path: ${webhook_path:=/rest/items/}"
         log_debug "${notification_type} ID: ${webhook_id:0:2}********${webhook_id:0-2}"
         log_debug "${notification_type} notification URL: ${webhook_scheme}://${webhook_server}:${webhook_port}${webhook_path}${webhook_id:0:2}********${webhook_id:0-2}"
      elif [ "${notification_type}" = "Webhook" ] && [ "${webhook_server}" ] && [ "${webhook_id}" ]
      then
         if [ "${webhook_https}" = true ]
         then
            webhook_scheme="https"
         else
            webhook_scheme="http"
         fi
         log_info "${notification_type} notifications enabled"
         clean_notification_title
         notification_url="${webhook_scheme}://${webhook_server}:${webhook_port}${webhook_path}${webhook_id}"
         log_debug "${notification_type} server: ${webhook_server}"
         log_debug "${notification_type} port: ${webhook_port:=8123}"
         log_debug "${notification_type} path: ${webhook_path:=/api/webhook/}"
         log_debug "${notification_type} ID: ${webhook_id:0:2}********${webhook_id:0-2}"
         log_debug "${notification_type} notification URL: ${webhook_scheme}://${webhook_server}:${webhook_port}${webhook_path}${webhook_id:0:2}********${webhook_id:0-2}"
         log_debug "${notification_type} body keyword: ${webhook_body:=data}"
         if [ "${webhook_insecure}" ] &&  [ "${debug_logging}" = true ]
         then
            log_debug "${notification_type} insecure certificates allowed"
         fi
      elif [ "${notification_type}" = "Discord" ] && [ "${discord_id}" ] && [ "${discord_token}" ]
      then
         log_info "${notification_type} notifications enabled"
         clean_notification_title
         notification_url="https://discord.com/api/webhooks/${discord_id}/${discord_token}"
         log_debug "${notification_type} Discord ID: ${discord_id:0:2}********${discord_id:0-2}"
         log_debug "${notification_type} Discord token: ${discord_token:0:2}********${discord_token:0-2}"
         log_debug "${notification_type} notification URL: https://discord.com/api/webhooks/${discord_id:0:2}********${discord_id:0-2}/${discord_token:0:2}********${discord_token:0-2}"
      elif [ "${notification_type}" = "Dingtalk" ] && [ "${dingtalk_token}" ]
      then
         notification_url="https://oapi.dingtalk.com/robot/send?access_token=${dingtalk_token}"
         log_info "${notification_type} notifications enabled"
         log_debug "${notification_type} token: ${dingtalk_token:0:2}********${dingtalk_token:0-2}"
         log_debug "${notification_type} notification URL: https://oapi.dingtalk.com/robot/send?access_token=${dingtalk_token:0:2}********${dingtalk_token:0-2}"
      elif [ "${notification_type}" = "IYUU" ] && [ "${iyuu_token}" ]
      then
         notification_url="http://iyuu.cn/${iyuu_token}.send?"
         log_info "${notification_type} notifications enabled"
         log_debug "${notification_type} token: ${iyuu_token}"
         log_debug "${notification_type} notification URL: http://iyuu.cn/${iyuu_token:0:2}********${iyuu_token:0-2}.send?"
      elif [ "${notification_type}" = "WeCom" ] && [ "${wecom_id}" ] && [ "${wecom_secret}" ]
      then
         wecom_base_url="https://qyapi.weixin.qq.com"
         if [ "${wecom_proxy}" ]
         then
            wecom_base_url="${wecom_proxy}"
            log_debug "${notification_type} notifications proxy enabled : ${wecom_proxy}"
         fi
         wecom_token_url="${wecom_base_url}/cgi-bin/gettoken?corpid=${wecom_id}&corpsecret=${wecom_secret}"
         if [ "${fake_user_agent}" = true ]
         then
            wecom_token="$(/usr/bin/curl --silent --user-agent "${curl_user_agent}" --get "${wecom_token_url}" | awk -F\" '{print $10}')"
         else
            wecom_token="$(/usr/bin/curl --silent --get "${wecom_token_url}" | awk -F\" '{print $10}')"
         fi
         wecom_token_expiry="$(date --date='2 hour')"
         notification_url="${wecom_base_url}/cgi-bin/message/send?access_token=${wecom_token}"
         log_info "${notification_type} notifications enabled"
         log_debug "${notification_type} token: ${wecom_token:0:2}********${wecom_token:0-2}"
         log_debug "${notification_type} token expiry time: $(date -d "${wecom_token_expiry}")"
         log_debug "${notification_type} notification URL: ${wecom_base_url}/cgi-bin/message/send?access_token=${wecom_token:0:2}********${wecom_token:0-2}"
      elif [ "${notification_type}" = "Gotify" ] && [ "${gotify_app_token}" ] && [ "${gotify_server_url}" ]
      then
      if [ "${gotify_https}" = true ]
      then
            gotify_scheme="https"
         else
            gotify_scheme="http"
         fi
         log_info "${notification_type} notifications enabled"
         clean_notification_title
         notification_url="${gotify_scheme}://${gotify_server_url}/message?token=${gotify_app_token}"
         log_debug "${notification_type} token: ${gotify_app_token:0:2}********${gotify_app_token:0-2}"
         log_debug "${notification_type} server URL: ${gotify_scheme}://${gotify_server_url}"
         log_debug "${notification_type} notification URL: ${gotify_scheme}://${gotify_server_url}/message?token=${gotify_app_token:0:2}********${gotify_app_token:0-2}"
      elif [ "${notification_type}" = "Bark" ] && [ "${bark_device_key}" ] && [ "${bark_server}" ]
      then
         log_info "${notification_type} notifications enabled"
         clean_notification_title
         notification_url="http://${bark_server}/push"
         log_debug "${notification_type} device key: ${bark_device_key:0:2}********${bark_device_key:0-2}"
         log_debug "${notification_type} server: ${bark_server}"
         log_debug "${notification_type} notification URL: http://${bark_server}/push"
      elif [ "${notification_type}" = "msmtp" ] && [ "${msmtp_host}" ] && [ "${msmtp_port}" ] && [ "${msmtp_user}" ] && [ "${msmtp_pass}" ]
      then
         log_info "${notification_type} notifications enabled"
      else
         log_warning "${notification_type} notifications enabled, but configured incorrectly - disabling notifications"
         unset notification_type prowl_api_key pushover_user pushover_token telegram_token telegram_chat_id webhook_scheme webhook_server webhook_port webhook_id dingtalk_token discord_id discord_token iyuu_token wecom_id wecom_secret gotify_app_token gotify_scheme gotify_server_url bark_device_key bark_server
      fi

      if [ "${startup_notification}" = true ]
      then
         log_debug "Startup notification: Enabled"
         if [ "${icloud_china}" = false ]
         then
            send_notification "startup" "iCloudPD container started" "0" "iCloudPD container starting for Apple ID: ${apple_id}"
         else
            send_notification "startup" "iCloudPD container started" "0" "启动成功，开始同步当前 Apple ID 中的照片" "" "" "" "开始同步 ${name} 的 iCloud 图库" "Apple ID: ${apple_id}"
         fi
      else
         log_debug "Startup notification: Disabled"
      fi

      if [ "${download_notifications}" = true ]
      then
         log_debug "Download notifications: Enabled"
      else
         log_debug "Download notifications: Disabled"
         unset download_notifications
      fi
      if [ "${delete_notifications}" = true ]
      then
         log_debug "Delete notifications: Enabled"
      else
         log_debug "Delete notifications: Disabled"
         unset delete_notifications
      fi
   fi
}

list_libraries()
{
   local shared_libraries
   if [ "${authentication_type}" = "MFA" ]
   then
      check_multifactor_authentication_cookie
   else
      check_web_cookie
   fi
   IFS=$'\n'
   if [ "${skip_download}" = false ]
   then
      shared_libraries="$(run_as "/opt/icloudpd/bin/icloudpd --username ${apple_id} --cookie-directory /config --domain ${auth_domain} --directory /dev/null --list-libraries | sed '1d'")"
   fi
   log_info "Shared libraries:"
   for library in ${shared_libraries}
   do
      log_info " - ${library}"
   done
   IFS="${save_ifs}"
}

list_albums()
{
   local photo_albums
   if [ "${authentication_type}" = "MFA" ]
   then
      check_multifactor_authentication_cookie
   else
      check_web_cookie
   fi
   IFS=$'\n'
   if [ "${skip_download}" = false ]
   then
      photo_albums="$(run_as "/opt/icloudpd/bin/icloudpd --username ${apple_id} --cookie-directory /config --domain ${auth_domain} --directory /dev/null --list-albums | sed '1d' | sed '/^Albums:$/d'")"
   fi
   log_info "Photo albums:"
   for photo_album in ${photo_albums}
   do
      log_info " - ${photo_album}"
   done
   IFS="${save_ifs}"
}

delete_password()
{
   if [ -f "/config/python_keyring/keyring_pass.cfg" ]
   then
      log_warning "Keyring file /config/python_keyring/keyring_pass.cfg exists, but --remove-keyring command line switch has been invoked. Removing in 30 seconds"
      if [ -z "${warnings_acknowledged}" ]
      then
         sleep 30
      else
         log_info "Warnings acknowledged, removing immediately"
      fi
      rm "/config/python_keyring/keyring_pass.cfg"
   else
      log_error "Keyring file does not exist"
   fi
}

configure_password()
{
   log_debug "Configure password"
   if [ -f "/config/python_keyring/keyring_pass.cfg" ]
   then
      if [ "$(grep -c "=" "/config/python_keyring/keyring_pass.cfg")" -eq 0 ]
      then
         log_debug "Keyring file /config/python_keyring/keyring_pass.cfg exists, but does not contain any credentials. Removing"
         rm "/config/python_keyring/keyring_pass.cfg"
      fi
   fi
   if [ ! -f "/config/python_keyring/keyring_pass.cfg" ]
   then
      if [ "${initialise_container}" ]
      then
         log_debug "Adding password to keyring file: /config/python_keyring/keyring_pass.cfg"
         run_as "/opt/icloudpd/bin/icloud --username ${apple_id} --domain ${auth_domain}"
      else
         log_error "Keyring file /config/python_keyring/keyring_pass.cfg does not exist"
         log_error " - Please add the your password to the system keyring using the --Initialise script command line option"
         log_error " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
         log_error " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
         log_error "Waiting for keyring file to be created..."
         local counter
         counter="${counter:=0}"
         while [ ! -f "/config/python_keyring/keyring_pass.cfg" ]
         do
            sleep 5
            counter=$((counter + 1))
            if [ "${counter}" -eq 360 ]
            then
               log_error "Keyring file has not appeared within 30 minutes. Restarting container..."
               exit 1
            fi
         done
         log_debug "Keyring file exists, continuing"
      fi
   else
      log_debug "Using password stored in keyring file: /config/python_keyring/keyring_pass.cfg"
   fi
   if [ ! -f "/config/python_keyring/keyring_pass.cfg" ]
   then
      log_error "Keyring file does not exist. Please try again"
      sleep 120
      exit 1
   fi
}

generate_cookie()
{
   if [ -f "/config/${cookie_file}" ]
   then
      mv "/config/${cookie_file}" "/config/${cookie_file}.bak"
   fi
   if [ -f "/config/${cookie_file}.session" ]
   then
      mv "/config/${cookie_file}.session" "/config/${cookie_file}session.bak"
   fi
   log_debug "Generate ${authentication_type} cookie using password stored in keyring file"
   run_as "/opt/icloudpd/bin/icloudpd --username ${apple_id} --cookie-directory /config --auth-only --domain ${auth_domain}"
   if [ "${authentication_type}" = "MFA" ]
   then
      if [ "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "/config/${cookie_file}")" -eq 1 ]
      then
         log_info "Multifactor authentication cookie generated. Sync should now be successful"
      else
         log_error "Multifactor authentication information missing from cookie. Authentication has failed"
         log_error " - Was the correct password entered?"
         log_error " - Was the multifactor authentication code mistyped?"
         log_error " - Can you log into ${icloud_domain} without receiving pop-up notifications?"
         if [ "${icloud_china}" = true ]
         then
            log_error " - Are you based in China? You will need to set the icloud_china variable"
         fi
      fi
   else
      log_debug "Web cookie generated. Sync should now be successful"
   fi
}

check_mount()
{
   log_info "Check download directory mounted correctly..."
   if [ ! -f "${download_path}/.mounted" ]
   then
      log_warning "Failsafe file ${download_path}/.mounted file is not present. Waiting for failsafe file to be created..."
      local counter
      counter="0"
   fi
   while [ ! -f "${download_path}/.mounted" ]
   do
      sleep 5
      counter=$((counter + 1))
      if [ "${counter}" -eq 360 ]
      then
         log_error "Failsafe file has not appeared within 30 minutes. Restarting container..."
         exit 1
      fi
   done
   log_info "Failsafe file ${download_path}/.mounted exists, continuing"
}

check_permissions()
{
   if [ "$(run_as "${user}" "if ! test -w \"${download_path}\"; then echo false; fi")" = false ]
   then
      log_warning "User ${user}:${user_id} cannot write to directory: ${download_path} - Attempting to set permissions"
      # set_owner_and_permissions_downloads
      if [ "$(run_as "${user}" "if ! test -w \"${download_path}\"; then echo false; fi")" = false ]
      then
         log_error "User ${user}:${user_id} still cannot write to directory: ${download_path}"
         log_error " - Fixing permissions failed - Cannot continue, exiting"
         sleep 120
         exit 1
      fi
   fi
   if [ "$(run_as "${user}" "if ! test -w \"${jpeg_path}\"; then echo false; fi")" = false ]
   then
      log_warning "User ${user}:${user_id} cannot write to directory: ${jpeg_path} - Attempting to set permissions"
      # set_owner_and_permissions_downloads
      if [ "$(run_as "${user}" "if ! test -w \"${jpeg_path}\"; then echo false; fi")" = false ]
      then
         log_error "User ${user}:${user_id} still cannot write to directory: ${jpeg_path}"
         log_error " - Fixing permissions failed - Cannot continue, exiting"
         sleep 120
         exit 1
      fi
   fi
}

check_keyring_exists()
{
   if [ -f "/config/python_keyring/keyring_pass.cfg" ]
   then
      log_info "Keyring file exists, continuing"
   else
      log_error "Keyring does not exist"
      log_error " - Please add your password to the system keyring by using the --Initialise script command line option"
      log_error " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
      log_error " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
      log_error "Waiting for keyring file to be created..."
      local counter
      counter="${counter:=0}"
      while [ ! -f "/config/python_keyring/keyring_pass.cfg" ]
      do
         sleep 5
         counter=$((counter + 1))
         if [ "${counter}" -eq 360 ]
         then
            log_error "Keyring file has not appeared within 30 minutes. Restarting container..."
            exit 1
         fi
      done
      log_info "Keyring file exists, continuing"
   fi
}

wait_for_cookie()
{
   if [ "${1}" = "DisplayMessage" ]
   then
      log_error "Waiting for valid cookie file to be created..."
      log_error " - Please create your cookie using the --Initialise script command line option"
      log_error " - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
      log_error " - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
   fi
   local counter
   counter="${counter:=0}"
   while [ ! -f "/config/${cookie_file}" ]
   do
      sleep 5
      counter=$((counter + 1))
      if [ "${counter}" -eq 360 ]
      then
         log_error "Valid cookie file has not appeared within 30 minutes. Restarting container..."
         exit 1
      fi
   done
}

wait_for_authentication()
{
   local counter
   counter="${counter:=0}"
   while [ "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "/config/${cookie_file}" >/dev/null 2>&1 && echo 1 || echo 0)" -eq 0 ]
   do
      sleep 5
      counter=$((counter + 1))
      if [ "${counter}" -eq 360 ]
      then
         log_error "Valid cookie file has not appeared within 30 minutes. Restarting container..."
         exit 1
      fi
   done
}

check_web_cookie()
{
   if [ -f "/config/${cookie_file}" ]
   then
      log_debug "Web cookie exists"
      web_cookie_expire_date="$(grep "X_APPLE_WEB_KB" "/config/${cookie_file}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   else
      log_error "Web cookie does not exist"
      wait_for_cookie DisplayMessage
      log_info "Cookie file exists, continuing"
   fi
}

check_multifactor_authentication_cookie()
{
   if [ -f "/config/${cookie_file}" ]
   then
      log_debug "Multifactor authentication cookie exists"
   else
      log_error "Multifactor authentication cookie does not exist"
      wait_for_cookie DisplayMessage
      log_debug "Multifactor authentication cookie file exists, checking validity..."
   fi
   if [ "$(grep -c "X-APPLE-DS-WEB-SESSION-TOKEN" "/config/${cookie_file}")" -eq 1 ] && [ "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "/config/${cookie_file}")" -eq 0 ]
   then
      log_debug "Multifactor authentication cookie exists, but not autenticated. Waiting for authentication to complete..."
      wait_for_authentication
      log_debug "Multifactor authentication authentication complete, checking expiry date..."
   fi
   if [ "$(grep -c "X-APPLE-WEBAUTH-USER" "/config/${cookie_file}")" -eq 1 ]
   then
      mfa_expire_date="$(grep "X-APPLE-WEBAUTH-USER" "/config/${cookie_file}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
      mfa_expire_seconds="$(date -d "${mfa_expire_date}" '+%s')"
      days_remaining="$(($((mfa_expire_seconds - $(date '+%s'))) / 86400))"
      echo "${days_remaining}" > "/config/DAYS_REMAINING"
      if [ "${days_remaining}" -gt 0 ]
      then
         valid_mfa_cookie=true
         log_debug "Valid multifactor authentication cookie found. Days until expiration: ${days_remaining}"
      else
         rm -f "/config/${cookie_file}"
         log_error "Cookie expired at: ${mfa_expire_date}"
         log_error "Expired cookie file has been removed. Restarting container in 5 minutes"
         sleep 300
         exit 1
      fi
   else
      rm -f "/config/${cookie_file}"
      log_error "Cookie is not multifactor authentication capable, authentication type may have changed"
      log_error "Invalid cookie file has been removed. Restarting container in 5 minutes"
      sleep 300
      exit 1
   fi
}

display_multifactor_authentication_expiry()
{
   local error_message
   log_info "Multifactor authentication cookie expires: ${mfa_expire_date/ / @ }"
   log_info "Days remaining until expiration: ${days_remaining}"
   if [ "${days_remaining}" -le "${notification_days}" ]
   then
      if [ "${days_remaining}" -eq 1 ]
      then
         cookie_status="cookie expired"
         if [ "${icloud_china}" = false ]
         then
            error_message="Final day before multifactor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise now. This is your last reminder"
         else
            error_message="今天是 ${name} 的 Apple ID 两步验证 cookie 到期前的最后一天 - 请立即重新初始化，这是最后的提醒"
         fi
      else
         cookie_status="cookie expiration"
         if [ "${icloud_china}" = false ]
         then
            error_message="Only ${days_remaining} days until multifactor authentication cookie expires for Apple ID: ${apple_id} - Please reinitialise"
         else
            error_message="${days_remaining} 天后 ${name} 的 Apple ID 两步验证将到期 - 请立即重新初始化"
         fi
      fi
      log_warning "${error_message}"
      if [ "${synchronisation_time:=$(date +%s -d '+15 minutes')}" -gt "${next_notification_time:=$(date +%s)}" ]
      then
         if [ "${icloud_china}" = false ]
         then
            send_notification "${cookie_status}" "Multifactor Authentication Cookie Expiration" "2" "${error_message}"
         else
            send_notification "${cookie_status}" "Multifactor Authentication Cookie Expiration" "2" "${error_message}" "" "" "" "${days_remaining} 天后，${name} 的身份验证到期" "${error_message}"
         fi
         next_notification_time="$(date +%s -d "+24 hour")"
         log_debug "Next notification not before: $(date +%H:%M:%S -d "${next_notification_time} seconds")"
      fi
   fi
}

check_files()
{
   if [ -f "/tmp/icloudpd/icloudpd_check.log" ]
   then
      rm "/tmp/icloudpd/icloudpd_check.log"
   fi
   log_info "Check for new files using password stored in keyring file"
   log_info "Generating list of files in iCloud. This may take a long time if you have a large photo collection. Please be patient. Nothing is being downloaded at this time"
   log_debug "Launch command: /opt/icloudpd/bin/icloudpd --directory ${download_path} --cookie-directory /config --username ${apple_id} --domain ${auth_domain} --folder-structure ${folder_structure} --only-print-filenames"
   >/tmp/icloudpd/icloudpd_check_error
   run_as "(/opt/icloudpd/bin/icloudpd --directory ${download_path} --cookie-directory /config --username ${apple_id} --domain ${auth_domain} --folder-structure ${folder_structure} --only-print-filenames 2>/tmp/icloudpd/icloudpd_check_error; echo $? >/tmp/icloudpd/icloudpd_check_exit_code) | tee /tmp/icloudpd/icloudpd_check.log"
   check_exit_code="$(cat /tmp/icloudpd/icloudpd_check_exit_code)"
   if [ "${check_exit_code}" -ne 0 ] || [ -s /tmp/icloudpd/icloudpd_check_error ]
   then
      log_error "Failed check for new files files"
      log_error " - Can you log into ${icloud_domain} without receiving pop-up notifications?"
      log_error "Error debugging info:"
      log_error "$(cat /tmp/icloudpd/icloudpd_check_error)"
      if [ "${debug_logging}" != true ]
      then
         log_error "Please set debug_logging=true in your icloudpd.conf file then reproduce the error"
         log_error "***** Once you have captured this log file, please post it along with a description of your problem, here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
      else
         log_error "***** Please post the above debug log, along with a description of your problem, here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
      fi
      if [ "${icloud_china}" = false ]
      then
         send_notification "failure" "iCloudPD container failure" "0" "iCloudPD failed check for new files for Apple ID: ${apple_id}"
      else
         syn_end_time="$(date '+%H:%M:%S')"
         syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
         send_notification "failure" "iCloudPD container failure" "0" "检查 iCloud 图库新照片失败，将在 ${syn_next_time} 再次尝试" "" "" "" "检查 ${name} 的 iCloud 图库新照片失败" "将在 ${syn_next_time} 再次尝试"
      fi
   else
      log_info "Check successful"
      check_files_count="$(wc --lines /tmp/icloudpd/icloudpd_check.log | awk '{print $1}')"
      if [ "${check_files_count}" -gt 0 ]
      then
         log_info "New files detected: ${check_files_count}"
      else
         log_info "No new files detected. Nothing to download"
      fi
   fi
   login_counter=$((login_counter + 1))
}

downloaded_files_notification()
{
   IFS=$'\n'
   local new_files_count new_files_preview new_files_text
   new_files="$(grep "Downloaded /" /tmp/icloudpd/icloudpd_sync.log)"
   new_files_count="$(grep -c "Downloaded /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${new_files_count:=0}" -gt 0 ]
   then
      log_info "New files downloaded: ${new_files_count}"
      new_files_preview="$(echo "${new_files}" | cut --delimiter " " --fields 9- | sed -e "s%${download_path}/%%g" | head -10)"
      new_files_preview_count="$(echo "${new_files_preview}" | wc -l)"
      if [ "${icloud_china}" = false ]
      then
         new_files_text="Files downloaded for Apple ID ${apple_id}: ${new_files_count}"
         send_notification "downloaded files" "New files detected" "0" "${new_files_text}" "${new_files_preview_count}" "downloaded" "${new_files_preview}"
      else
         # 结束时间、下次同步时间
         syn_end_time="$(date '+%H:%M:%S')"
         syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
         new_files_text="iCloud 图库同步完成，新增 ${new_files_count} 张照片"
         send_notification "downloaded files" "New files detected" "0" "${new_files_text}" "${new_files_preview_count}" "下载" "${new_files_preview}" "新增 ${new_files_count} 张照片 - ${name}" "下次同步时间 ${syn_next_time}"
      fi
   fi
   IFS="${save_ifs}"
}

deleted_files_notification()
{
   IFS=$'\n'
   local deleted_files deleted_files_count deleted_files_preview deleted_files_text
   deleted_files="$(grep "Deleted /" /tmp/icloudpd/icloudpd_sync.log)"
   deleted_files_count="$(grep -c "Deleted /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${deleted_files_count:=0}" -gt 0 ]
   then
      log_info "Number of files deleted: ${deleted_files_count}"
      deleted_files_preview="$(echo "${deleted_files}" | cut --delimiter " " --fields 9- | sed -e "s%${download_path}/%%g" -e "s%!$%%g" | tail -10)"
      deleted_files_preview_count="$(echo "${deleted_files_preview}" | wc -l)"
      if [ "${icloud_china}" = false ]
      then
         deleted_files_text="Files deleted for Apple ID ${apple_id}: ${deleted_files_count}"
         send_notification "deleted files" "Recently deleted files detected" "0" "${deleted_files_text}" "${deleted_files_preview_count}" "deleted" "${deleted_files_preview}"
      else
         # 结束时间、下次同步时间
         syn_end_time="$(date '+%H:%M:%S')"
         syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
         deleted_files_text="iCloud 图库同步完成，删除 ${deleted_files_count} 张照片"
         send_notification "deleted files" "Recently deleted files detected" "0" "${deleted_files_text}" "${deleted_files_preview_count}" "删除" "${deleted_files_preview}" "删除 ${deleted_files_count} 张照片 - ${name}" "下次同步时间 ${syn_next_time}"
      fi
   fi
   IFS="${save_ifs}"
}

download_albums()
{
   local all_albums albums_to_download
   if [ "${photo_album}" = "all albums" ]
   then
      all_albums="$(run_as "/opt/icloudpd/bin/icloudpd --username ${apple_id} --cookie-directory /config --domain ${auth_domain} --directory /dev/null --list-albums | sed '1d' | sed '/^Albums:$/d'")"
      log_debug "Buildling list of albums to download..."
      IFS=$'\n'
      for album in ${all_albums}
      do
         if [ "${skip_album}" ]
         then
            if [ ! "${skip_album}" = "${album}" ]
            then
               log_debug " - ${album}"
               if [ -z "${albums_to_download}" ]
               then
                  albums_to_download="${album}"
               else
                  albums_to_download="${albums_to_download},${album}"
               fi
            fi
         else
            log_debug " - ${album}"
            if [ -z "${albums_to_download}" ]
            then
               albums_to_download="${album}"
            else
               albums_to_download="${albums_to_download},${album}"
            fi
         fi
      done
   else
      albums_to_download="${photo_album}"
   fi
   IFS=","
   log_debug "Starting albums download..."
   for album in ${albums_to_download}
   do
      log_info "Downloading album: ${album}"
      if [ "${albums_with_dates}" = true ]
      then
         log_debug "iCloudPD launch command: /opt/icloudpd/bin/icloudpd ${command_line} --log-level ${log_level} --folder-structure \"${album}/${folder_structure}\" --album \"${album}\" 2>/tmp/icloudpd/icloudpd_download_error"
         run_as "(/opt/icloudpd/bin/icloudpd ${command_line} --log-level ${log_level} --folder-structure \"${album}/${folder_structure}\" --album \"${album}\" 2>/tmp/icloudpd/icloudpd_download_error; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log"
      else
         log_debug "iCloudPD launch command: /opt/icloudpd/bin/icloudpd ${command_line} --log-level ${log_level} --folder-structure \"${album}\" --album \"${album}\" 2>/tmp/icloudpd/icloudpd_download_error"
         run_as "(/opt/icloudpd/bin/icloudpd ${command_line} --log-level ${log_level} --folder-structure \"${album}\" --album \"${album}\" 2>/tmp/icloudpd/icloudpd_download_error; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log"
      fi
      if [ "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" -ne 0 ]
      then
         log_error "Failed downloading album: ${album}"
         IFS="${save_ifs}"
         sleep 10
         break
      fi
   done
   IFS="${save_ifs}"
}

download_libraries()
{
   local all_libraries libraries_to_download
   if [ "${photo_library}" = "all libraries" ]
   then
      log_debug "Fetching libraries list..."
      all_libraries="$(run_as "/opt/icloudpd/bin/icloudpd --username ${apple_id} --cookie-directory /config --domain ${auth_domain} --directory /dev/null --list-libraries | sed '1d'")"
      log_debug "Building list of libraries to download..."
      IFS=$'\n'
      for library in ${all_libraries}
      do
         if [ "${skip_library}" ]
         then
            if [ ! "${skip_library}" = "${library}" ]
            then
               log_debug " - ${library}"
               if [ -z "${libraries_to_download}" ]
               then
                  libraries_to_download="${library}"
               else
                  libraries_to_download="${libraries_to_download},${library}"
               fi
            fi
         else
            log_debug " - ${library}"
            if [ -z "${libraries_to_download}" ]
            then
               libraries_to_download="${library}"
            else
               libraries_to_download="${libraries_to_download},${library}"
            fi
         fi
      done
   else
      libraries_to_download="${photo_library}"
   fi
   IFS=","
   for library in ${libraries_to_download}
   do
      log_info "Downloading library: ${library}"
      if [ "${libraries_with_dates}" = true ]
      then
         log_debug "iCloudPD launch command: /opt/icloudpd/bin/icloudpd ${command_line} --log-level ${log_level} --folder-structure ${library}/${folder_structure} --library ${library} 2>/tmp/icloudpd/icloudpd_download_error"
         run_as "(/opt/icloudpd/bin/icloudpd ${command_line} --log-level "${log_level}" --folder-structure "${library}/${folder_structure}" --library "${library}" 2>/tmp/icloudpd/icloudpd_download_error; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log"
      else
         log_debug "iCloudPD launch command: /opt/icloudpd/bin/icloudpd ${command_line} --log-level ${log_level} --folder-structure ${library} --library ${library} 2>/tmp/icloudpd/icloudpd_download_error"
         run_as "(/opt/icloudpd/bin/icloudpd ${command_line} --log-level "${log_level}" --folder-structure "${library}" --library "${library}" 2>/tmp/icloudpd/icloudpd_download_error; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log"
      fi
      if [ "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" -ne 0 ]
      then
         log_error "Failed downloading library: ${library}"
         IFS="${save_ifs}"
         sleep 10
         break
      fi
   done
   IFS="${save_ifs}"
}

download_photos()
{
   log_debug "iCloudPD launch command: /opt/icloudpd/bin/icloudpd --log-level ${log_level} ${command_line} 2>/tmp/icloudpd/icloudpd_download_error"
   if [ "${skip_download}" = false ]
   then
      run_as "(/opt/icloudpd/bin/icloudpd ${command_line} --log-level ${log_level} 2>/tmp/icloudpd/icloudpd_download_error; echo $? >/tmp/icloudpd/icloudpd_download_exit_code) | tee /tmp/icloudpd/icloudpd_sync.log"
   else
      log_debug "Skip download: ${skip_download} - skipping"
      echo 0 >/tmp/icloudpd/icloudpd_download_exit_code
      touch /tmp/icloudpd/icloudpd_sync.log
   fi
}

check_nextcloud_connectivity()
{
   local nextcloud_check_result counter
   log_info "Checking Nextcloud connectivity..."
   nextcloud_check_result="$(curl --silent --max-time 15 --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --output /dev/null "${nextcloud_url%/}/remote.php/dav/files/${nextcloud_username}/")"
   if [ "${nextcloud_check_result}" -ne 200 ]
   then
      log_error "Nextcloud connectivity check failed: ${nextcloud_check_result}"
      fail_time="$(date "+%a %d %B %H:%M:%S (%Z) %Y")"
      send_notification "Nextcloud" "failed" "0" "Nextcloud connectivity check failed for user: ${user}. Waiting for server to come back online..."
      while [ "${nextcloud_check_result}" -ne 200 ]
      do
         sleep 45
         counter=$((counter + 1))
         if [ "${counter}" -eq 15 ] || [ "${counter}" -eq 60 ] || [ "${counter}" -eq 300 ]
         then
            send_notification "Nextcloud" "failed" "0" "Nextcloud has been offline for user ${user} since ${fail_time}. Please take corrective action. icloudpd will remain paused until this issue is rectified"
         fi
         nextcloud_check_result="$(curl --silent --location --max-time 15 --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --output /dev/null "${nextcloud_url%/}/remote.php/dav/files/${nextcloud_username}/")"
      done
      send_notification "Nextcloud" "success" "0" "Nextcloud server is back online. Resuming operation"
   fi
}

nextcloud_url_encoder()
{
   echo "$@" | sed \
      -e 's/%/%25/g' \
      -e 's/ /%20/g' \
      -e 's/!/%21/g' \
      -e 's/"/%22/g' \
      -e "s/'/%27/g" \
      -e 's/#/%23/g' \
      -e 's/(/%28/g' \
      -e 's/)/%29/g' \
      -e 's/+/%2b/g' \
      -e 's/,/%2c/g' \
      -e 's/:/%3a/g' \
      -e 's/;/%3b/g' \
      -e 's/?/%3f/g' \
      -e 's/@/%40/g' \
      -e 's/\$/%24/g' \
      -e 's/\&/%26/g' \
      -e 's/\*/%2a/g' \
      -e 's/\[/%5b/g' \
      -e 's/\\/%5c/g' \
      -e 's/\]/%5d/g' \
      -e 's/\^/%5e/g' \
      -e 's/`/%60/g' \
      -e 's/{/%7b/g' \
      -e 's/|/%7c/g' \
      -e 's/}/%7d/g' \
      -e 's/~/%7e/g'
}

nextlcoud_create_directories()
{
   IFS=$'\n'
   local destination_directories encoded_destination_directories curl_response
   log_info "Checking Nextcloud destination directories..."
   destination_directories=$(grep "Downloaded /" /tmp/icloudpd/icloudpd_sync.log | cut --delimiter " " --fields 9- | sed "s%${download_path}%%" | while read -r line
      do
         for level in $(seq 1 $(echo "${line}" | tr -cd '/' | wc -c))
         do
            echo "${line}" | cut -d'/' -f1-"${level}"
         done
      done | sort --unique)

   encoded_destination_directories=$(for destination_directory in $destination_directories
      do
         echo "${nextcloud_url%/}/remote.php/dav/files/$(echo $(nextcloud_url_encoder "${nextcloud_username}/${nextcloud_target_dir%/}${destination_directory}/"))"
      done)
   IFS="${save_ifs}"

   for nextcloud_destination in ${encoded_destination_directories}; do
      log_info_n " - ${nextcloud_destination} "
      curl_response="$(curl --silent --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --output /dev/null "${nextcloud_destination}")"
      if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
      then
         echo "Exists"
      else
         echo "Missing"
         log_info_n "Creating Nextcloud directory: ${nextcloud_destination} "
         curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --request MKCOL "${nextcloud_destination}")"
         if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
         then
            echo "Success"
         else
            echo "Error: ${curl_response}"
         fi
      fi
   done
}

nextcloud_sync()
{
   local new_files_count deleted_files_count

   new_files_count="$(grep -c "Downloaded /" /tmp/icloudpd/icloudpd_sync.log)"
   deleted_files_count="$(grep -c "Deleted /" /tmp/icloudpd/icloudpd_sync.log)"

   if [ "${new_files_count:=0}" -gt 0 ]
   then
      check_nextcloud_connectivity
      nextlcoud_create_directories
      nextcloud_upload
   fi

   if [ "${deleted_files_count:=0}" -gt 0 ]
   then
      if [ "${nextcloud_delete}" = true ]
      then
         check_nextcloud_connectivity
         nextcloud_delete
         nextlcoud_delete_directories
      fi
   fi
}

nextcloud_upload()
{
   IFS=$'\n'
   local nextcloud_destination curl_response
   log_info "Uploading files to Nextcloud"
   for full_filename in $(grep "Downloaded /" /tmp/icloudpd/icloudpd_sync.log | cut --delimiter " " --fields 9-)
   do
      nextcloud_destination="${nextcloud_url%/}/remote.php/dav/files/$(nextcloud_url_encoder "${nextcloud_username}/${nextcloud_target_dir%/}$(echo ${full_filename} | sed "s%${download_path}%%")")"
      if [ ! -f "${full_filename}" ]
      then
         log_warning "Media file ${full_filename} does not exist. It may exist in 'Recently Deleted' so has been removed post download"
      else
         log_info_n "Uploading ${full_filename} to ${nextcloud_destination}"
         curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --upload-file "${full_filename}" "${nextcloud_destination}")"
         if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
         then
            echo "Success"
         else
            echo "Unexpected response: ${curl_response}"
         fi
         if [ -f "${full_filename%.HEIC}.JPG" ]
         then
            log_info_n "Uploading ${full_filename} to ${nextcloud_destination%.HEIC}.JPG"
            curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --upload-file "${full_filename}" "${nextcloud_destination%.HEIC}.JPG")"
            if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
            then
               echo "Success"
            else
               echo "Unexpected response: ${curl_response}"
            fi
         fi
         if [ -f "${full_filename%.heic}.jpg" ]
         then
            log_info_n "Uploading ${full_filename} to ${nextcloud_destination%.heic}.jpg"
            curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --upload-file "${full_filename}" "${nextcloud_destination%.heic}.jpg")"
            if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
            then
               echo "Success"
            else
               echo "Unexpected response: ${curl_response}"
            fi
         fi
      fi
   done
   IFS="${save_ifs}"
}

nextcloud_delete()
{
   IFS=$'\n'
   local nextcloud_destination curl_response
   log_info "Delete files from Nextcloud..."
   for full_filename in $(grep "Deleted /" /tmp/icloudpd/icloudpd_sync.log | cut --delimiter " " --fields 9-)
   do
      nextcloud_destination="${nextcloud_url%/}/remote.php/dav/files/$(nextcloud_url_encoder "${nextcloud_username}/${nextcloud_target_dir%/}$(echo ${full_filename} | sed "s%${download_path}%%")")"
      log_debug "Checking file path: ${nextcloud_destination}"
      curl_response="$(curl --silent --show-error --location --head --user "${nextcloud_username}:${nextcloud_password}" "${nextcloud_destination}" --output /dev/null --write-out "%{http_code}")"
      if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 200 ]
      then
         log_info_n " - File exists, deleting"
         if curl --silent --show-error --location --request DELETE --user "${nextcloud_username}:${nextcloud_password}" --output /dev/null "${nextcloud_destination}"
         then
            echo "Success"
         else
            echo "Error: $?"
         fi
      elif [ "${curl_response}" -eq 404 ]
      then
         echo "File not found: ${nextcloud_destination}"
      else
         echo "Unexpected response: ${curl_response}"
      fi
      if [ -f "${full_filename%.HEIC}.JPG" ]
      then
         log_debug "Checking file path: ${nextcloud_destination%.HEIC}.JPG"
         curl_response="$(curl --silent --show-error --location --head --user "${nextcloud_username}:${nextcloud_password}" "${nextcloud_destination%.HEIC}.JPG" --output /dev/null --write-out "%{http_code}")"
         if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 200 ]
         then
            log_info_n " - File exists, deleting"
            if curl --silent --show-error --location --request DELETE --user "${nextcloud_username}:${nextcloud_password}" --output /dev/null "${nextcloud_destination%.HEIC}.JPG"
            then
               echo "Success"
            else
               echo "Error: $?"
            fi
         elif [ "${curl_response}" -eq 404 ]
         then
            echo "File not found: ${nextcloud_destination%.HEIC}.JPG"
         else
            echo "Unexpected response: ${curl_response}"
         fi
      fi
      if [ -f "${full_filename%.heic}.jpg" ]
      then
         log_debug "Checking file path: ${nextcloud_destination%.heic}.jpg"
         curl_response="$(curl --silent --show-error --location --head --user "${nextcloud_username}:${nextcloud_password}" "${nextcloud_destination%.heic}.jpg" --output /dev/null --write-out "%{http_code}")"
         if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 200 ]
         then
            log_info_n " - File exists, deleting"
            if curl --silent --show-error --location --request DELETE --user "${nextcloud_username}:${nextcloud_password}" --output /dev/null "${nextcloud_destination%.heic}.jpg"
            then
               echo "Success"
            else
               echo "Error: $?"
            fi
         elif [ "${curl_response}" -eq 404 ]
         then
            echo "File not found: ${nextcloud_destination%.heic}.jpg"
         else
            echo "Unexpected response: ${curl_response}"
         fi
      fi
   done
   IFS="${save_ifs}"
}

nextlcoud_delete_directories()
{
   IFS=$'\n'
   local directories_list nextcloud_target curl_response
   log_info "Checking for empty Nextcloud destination directories to remove..."
   directories_list="$(grep "Deleted /" /tmp/icloudpd/icloudpd_sync.log | cut --delimiter " " --fields 9- | sed 's~\(.*/\).*~\1~' | sed "s%${download_path}%%" | sort --unique --reverse | grep -v "^$")"
   for target_directory in ${directories_list}
   do
      nextcloud_target="${nextcloud_url%/}/remote.php/dav/files/$(nextcloud_url_encoder "${nextcloud_username}/${nextcloud_target_dir%/}${target_directory}")"
      log_debug "Checking if Nextcloud directory is empty: ${nextcloud_target}"
      curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --request PROPFIND "${nextcloud_target}" | grep -ow '<d:href>' | wc -l)"
      if [ "${curl_response}" -ge 2 ]
      then
         log_debug " - Not removing directory as it contains items: $((curl_response -1 ))"
      else
         log_info_n " - Removing empty Nextcloud directory: ${nextcloud_target}"
         curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --output /dev/null --request DELETE "${nextcloud_target}")"
         if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
         then
            echo "Success"
         else
            echo "Unexpected response: ${curl_response}"
         fi
      fi
   done
   IFS="${save_ifs}"
}

nextcloud_upload_library()
{
   log_info "Uploading entire library to Nextcloud. This may take a while..."
   local destination_directories encoded_destination_directories curl_response
   log_info "Checking Nextcloud destination directories..."
   destination_directories=$(find "${download_path}" -type d ! -name '.*' 2>/dev/null | sed "s%${download_path}%%" | grep -v "^$" | sort --unique)

   IFS=$'\n'
   encoded_destination_directories=$(for destination_directory in $destination_directories
      do
         echo "${nextcloud_url%/}/remote.php/dav/files/$(echo $(nextcloud_url_encoder "${nextcloud_username}/${nextcloud_target_dir%/}${destination_directory}/"))"
      done)
   IFS="${save_ifs}"

   for nextcloud_destination in ${encoded_destination_directories}; do
      log_info_n " - ${nextcloud_destination} "
      curl_response="$(curl --silent --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --output /dev/null "${nextcloud_destination}")"
      if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
      then
         echo "Exists"
      else
         echo "Missing"
         log_info_n "Creating Nextcloud directory: ${nextcloud_destination} "
         curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --request MKCOL "${nextcloud_destination}")"
         if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
         then
            echo "Success"
         else
            echo "Error: ${curl_response}"
         fi
      fi
   done

   log_info "Checking Nextcloud destination files..."
   IFS=$'\n'
   for full_filename in $(find "${download_path}" -type f ! -name '.*' 2>/dev/null | sed "s%${download_path}%%")
   do
      nextcloud_destination="${nextcloud_url%/}/remote.php/dav/files/$(nextcloud_url_encoder "${nextcloud_username}/${nextcloud_target_dir%/}$(echo ${full_filename})")"

      log_info_n "Uploading ${full_filename} to ${nextcloud_destination}"
      if curl --silent --output /dev/null --fail --head --user "${nextcloud_username}:${nextcloud_password}" "${nextcloud_destination}"
      then
         echo "File already exsits"
      else
         curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --upload-file "${full_filename}" "${nextcloud_destination}")"
         if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
         then
            echo "Success"
         else
            echo "Unexpected response: ${curl_response}"
         fi
      fi
      if [ -f "${full_filename%.HEIC}.JPG" ]
      then
         log_info_n "Uploading ${full_filename%.HEIC}.JPG to ${nextcloud_destination%.HEIC}.JPG"
         if curl --silent --output /dev/null --fail --head --user "${nextcloud_username}:${nextcloud_password}" "${nextcloud_destination%.HEIC}.JPG"
         then
            log_info_n "File already exsits"
         else
            curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --upload-file "${nextcloud_destination%.HEIC}.JPG")"
            if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
            then
               echo "Success"
            else
               echo "Unexpected response: ${curl_response}"
            fi
         fi
      fi
      if [ -f "${full_filename%.heic}.jpg" ]
      then
         log_info_n "Uploading ${full_filename%.heic}.jpg to ${nextcloud_destination%.heic}.jpg"
         if curl --silent --output /dev/null --fail --head --user "${nextcloud_username}:${nextcloud_password}" "${nextcloud_destination%.heic}.jpg"
         then
            log_info_n "File already exsits"
         else
            curl_response="$(curl --silent --show-error --location --user "${nextcloud_username}:${nextcloud_password}" --write-out "%{http_code}" --upload-file "${nextcloud_destination%.heic}.jpg")"
            if [ "${curl_response}" -ge 200 ] && [ "${curl_response}" -le 299 ]
            then
               echo "Success"
            else
               echo "Unexpected response: ${curl_response}"
            fi
         fi
      fi
   done
   IFS="${save_ifs}"
}

convert_downloaded_heic_to_jpeg()
{
   IFS=$'\n'
   log_info "Convert HEIC to JPEG..."
   for heic_file in $(grep "Downloaded /" /tmp/icloudpd/icloudpd_sync.log | grep ".HEIC" | cut --delimiter " " --fields 9-)
   do
      if [ ! -f "${heic_file}" ]
      then
         log_warning "HEIC file ${heic_file} does not exist. It may exist in 'Recently Deleted' so has been removed post download"
      else
         jpeg_file="${heic_file%.HEIC}.JPG"
         if [ "${jpeg_path}" ]
         then
            if [ ! -d "${jpeg_path}" ]
            then
               mkdir --parents "${jpeg_path}"
               chown "${user}:${group}" "${jpeg_path}"
            fi
            jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
            jpeg_directory="$(dirname "${jpeg_file/${download_path}/${jpeg_path}}")"
            if [ ! -d "${jpeg_directory}" ]
            then
               mkdir --parents "${jpeg_directory}"
               chown "${user}:${group}" "${jpeg_directory}"
            fi
         fi
         log_info "Converting ${heic_file} to ${jpeg_file}"
         magick -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
         heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
         log_debug "Timestamp of HEIC file: ${heic_date}"
         touch --reference="${heic_file}" "${jpeg_file}"
         log_debug "Setting timestamp of ${jpeg_file} to ${heic_date}"
         log_debug "Correct owner and group of ${jpeg_file} to ${user}:${group}"
         chown "${user}:${group}" "${jpeg_file}"
      fi
   done
   IFS="${save_ifs}"
}

sideways_copy_all_videos()
{
   # Copy videos sideways to alternate directory
   local video_list folder_list
   log_info "Sideways copy all videos to alternate directory..."
   if [ -z "${video_path}" ] 
   then
      log_error "Video path is not configured. Cannot sideways copy all videos. Exiting."
      sleep 120
      exit 1
   elif [ ! -d "${video_path}" ]
   then
      log_error "Video path configured does not exit: ${video_path}. Cannot sideways copy all videos. Exiting"
      sleep 120
      exit 1
   fi

   IFS=$'\n'
   video_list="$(find "${download_path}" -type f -iname "*.mp4" -o -iname "*.mov" | grep -vi hevc.mov)"
   folder_list="$(for line in ${video_list}; do echo ${line}; done | sort --unique)"
   destination_directories=$(echo "${folder_list}" | while read -r line
   do
      for level in $(seq 1 $(echo "${line}" | tr -cd '/' | wc -c))
      do
         echo "${line}" | cut -d'/' -f1-"${level}"
      done
   done | sort --unique)

   log_debug " - Creating destination folders..."
   for folder in ${destination_directories}
   do
      log_debug "   | Processing: ${folder}"
      if [ ! -d "${video_path}${folder}" ]
      then
         log_debug "   | Creating: ${video_path}${folder}"
         mkdir --parents "${video_path}${folder}" >/dev/null
         chown --reference="${folder}" "${video_path}${folder}"
         chmod --reference="${folder}" "${video_path}${folder}"
      fi
   done

   log_debug " - Sideways copying all videos with copy mode: ${sideways_copy_videos_mode}"
   for video in ${video_list}
   do
      if [ "${sideways_copy_videos_mode}" = "move" ] && [ "${delete_after_download}" = true ]
      then
         log_debug "   | Moving ${video} to ${video_path}${video}"
         mv --update=none --preserve "${video}" "${video_path}${video}"
      elif [ "${sideways_copy_videos_mode}" = "copy" ]
      then
         log_debug "   | Copying ${video} to ${video_path}${video}"
         cp --update=none --preserve "${video}" "${video_path}${video}"
      fi
   done
   IFS="${save_ifs}"
}

sideways_copy_videos()
{
   # Copy videos sideways to alternate directory
   local video_list folder_list
   log_info "Sideways copy videos to alternate directory..."
   if [ -z "${video_path}" ] 
   then
      log_error " - Video path is not configured. Cannot sideways copy all videos. Exiting."
      sleep 120
      exit 1
   elif [ ! -d "${video_path}" ]
   then
      log_error " - Video path configured does not exit: ${video_path}. Cannot sideways copy all videos. Exiting"
      sleep 120
      exit 1
   fi

   IFS=$'\n'
   video_list="$(grep "Downloaded /" /tmp/icloudpd/icloudpd_sync.log | grep -i ".mov$\|.mp4$" | grep -vi "hevc.mov$" | cut --delimiter " " --fields 9-)"
   folder_list="$(for line in ${video_list}; do echo ${line}; done | sort --unique)"
   destination_directories=$(echo "${folder_list}" | while read -r line
   do
      for level in $(seq 1 $(echo "${line}" | tr -cd '/' | wc -c))
      do
         echo "${line}" | cut -d'/' -f1-"${level}"
      done
   done | sort --unique)

   log_debug " - Creating destination folders..."
   for folder in ${destination_directories}
   do
      log_debug "   | Processing: ${folder}"
      if [ ! -d "${video_path}${folder}" ]
      then
         log_debug "   | Creating: ${video_path}${folder}"
         mkdir --parents "${video_path}${folder}" >/dev/null
         chown --reference="${folder}" "${video_path}${folder}"
         chmod --reference="${folder}" "${video_path}${folder}"
      fi
   done

   log_debug " - Sideways copying videos with copy mode: ${sideways_copy_videos_mode}"
   for video in ${video_list}
   do
      if [ "${sideways_copy_videos_mode}" = "move" ] && [ "${delete_after_download}" = true ]
      then
         log_debug "   | Moving ${video} to ${video_path}${video}"
         mv --update=none --preserve "${video}" "${video_path}${video}"
      elif [ "${sideways_copy_videos_mode}" = "copy" ]
      then
         log_debug "   | Copying ${video} to ${video_path}${video}"
         cp --update=none --preserve "${video}" "${video_path}${video}"
      fi
   done
   IFS="${save_ifs}"
}

synology_photos_app_fix()
{
   # Works for onestix. Do not obsolete
   IFS=$'\n'
   log_info "Fixing Synology Photos App import issue..."
   for heic_file in $(grep "Downloaded /" /tmp/icloudpd/icloudpd_sync.log | grep ".HEIC" | cut --delimiter " " --fields 9-)
   do
      log_debug "Create empty date/time reference file ${heic_file%.HEIC}.TMP"
      run_as "touch --reference=\"${heic_file}\" \"${heic_file%.HEIC}.TMP\""
      log_debug "Set time stamp for ${heic_file} to current: $(date)"
      run_as "touch \"${heic_file}\"" 
      log_debug "Set time stamp for ${heic_file} to original: $(date -r "${heic_file%.HEIC}.TMP" +"%a %b %e %T %Y")"
      run_as "touch --reference=\"${heic_file%.HEIC}.TMP\" \"${heic_file}\""
      log_debug "Removing temporary file ${heic_file%.HEIC}.TMP"
      if [ -z "${persist_temp_files}" ]
      then
         rm "${heic_file%.HEIC}.TMP"
      fi
   done
   IFS="${save_ifs}"
}

convert_all_heic_files()
{
   IFS=$'\n'
   log_info "Convert all HEICs to JPEG, if required..."
   for heic_file in $(find "${download_path}" -type f -iname *.HEIC 2>/dev/null); do
      log_debug "HEIC file found: ${heic_file}"
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]
      then
         if [ ! -d "${jpeg_path}" ]
         then
            mkdir --parents "${jpeg_path}"
            chown "${user}:${group}" "${jpeg_path}"
         fi
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
         jpeg_directory="$(dirname "${jpeg_file/${download_path}/${jpeg_path}}")"
         if [ ! -d "${jpeg_directory}" ]
         then
            mkdir --parents "${jpeg_directory}"
            chown "${user}:${group}" "${jpeg_directory}"
         fi
      fi
      if [ ! -f "${jpeg_file}" ]
      then
         log_info "Converting ${heic_file} to ${jpeg_file}"
         magick -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
         heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
         log_debug "Timestamp of HEIC file: ${heic_date}"
         touch --reference="${heic_file}" "${jpeg_file}"
         log_debug "Setting timestamp of ${jpeg_file} to ${heic_date}"
         log_debug "Correct owner and group of ${jpeg_file} to ${user}:${group}"
         chown "${user}:${group}" "${jpeg_file}"
      fi
   done
   IFS="${save_ifs}"
}

remove_all_jpeg_files()
{
   IFS=$'\n'
   log_warning "Remove all JPGs that have accompanying HEIC files. This could result in data loss if HEIC file name matches the JPG file name, but content does not"
   log_info "Waiting for 2mins before progressing. Please stop the container now, if this is not what you want to do..."
   sleep 120
   for heic_file in $(find "${download_path}" -type f -iname *.HEIC 2>/dev/null)
   do
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]
      then
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
      fi
      log_info "Removing ${jpeg_file}"
      if [ -f "${jpeg_file}" ]
      then
         rm "${jpeg_file}"
      fi
   done
   IFS="${save_ifs}"
}

force_convert_all_heic_files()
{
   IFS=$'\n'
   log_warning "Force convert all HEICs to JPEG. This could result in data loss if JPG files have been edited on disk"
   log_info "Waiting for 2mins before progressing. Please stop the container now, if this is not what you want to do..."
   sleep 120
   for heic_file in $(find "${download_path}" -type f -iname *.HEIC 2>/dev/null); do
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]
      then
         if [ ! -d "${jpeg_path}" ]
         then
            mkdir --parents "${jpeg_path}"
            chown "${user}:${group}" "${jpeg_path}"
         fi
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
         jpeg_directory="$(dirname "${jpeg_file/${download_path}/${jpeg_path}}")"
         if [ ! -d "${jpeg_directory}" ]
         then
            mkdir --parents "${jpeg_directory}"
            chown "${user}:${group}" "${jpeg_directory}"
         fi
      fi
      log_info "Converting ${heic_file} to ${jpeg_file}"
      if [ -f "${jpeg_file}" ]
      then
         rm "${jpeg_file}"
      fi
      magick -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
      heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
      log_debug "Timestamp of HEIC file: ${heic_date}"
      touch --reference="${heic_file}" "${jpeg_file}"
      log_debug "Setting timestamp of ${jpeg_file} to ${heic_date}"
      log_debug "Correct owner and group of ${jpeg_file} to ${user}:${group}"
      chown "${user_id}:${group_id}" "${jpeg_file}"
   done
   IFS="${save_ifs}"
}

force_convert_all_mnt_heic_files()
{
   IFS=$'\n'
   log_warning "Force convert all HEICs in /mnt directory to JPEG. This could result in data loss if JPG files have been edited on disk"
   log_info "Waiting for 2mins before progressing. Please stop the container now, if this is not what you want to do..."
   sleep 120
   for heic_file in $(find "/mnt" -type f -iname *.HEIC 2>/dev/null)
   do
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]
      then
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
      fi
      log_info "Converting ${heic_file} to ${jpeg_file}"
      rm "${jpeg_file}"
      magick -quality "${jpeg_quality}" "${heic_file}" "${jpeg_file}"
      heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
      log_debug "Timestamp of HEIC file: ${heic_date}"
      touch --reference="${heic_file}" "${jpeg_file}"
      log_debug "Setting timestamp of ${jpeg_file} to ${heic_date}"
      log_debug "Correct owner and group of ${jpeg_file} to ${user}:${group}"
      chown "${user}:${group}" "${jpeg_file}"
   done
   IFS="${save_ifs}"
}

correct_jpeg_timestamps()
{
   IFS=$'\n'
   log_info "Check and correct converted HEIC timestamps..."
   for heic_file in $(find "${download_path}" -type f -iname *.HEIC 2>/dev/null)
   do
      jpeg_file="${heic_file%.HEIC}.JPG"
      if [ "${jpeg_path}" ]
      then
         jpeg_file="${jpeg_file/${download_path}/${jpeg_path}}"
      fi
      heic_date="$(date -r "${heic_file}" +"%a %b %e %T %Y")"
      log_debug "Timestamp of HEIC file: ${heic_date}"
      if [ -f "${jpeg_file}" ]
      then
         log_debug "JPEG file found: ${jpeg_file}"
         jpeg_date="$(date -r "${jpeg_file}" +"%a %b %e %T %Y")"
         log_debug "Timestamp of JPEG file: ${jpeg_date}"
         if [ "${heic_date}" != "${jpeg_date}" ]
         then
            log_info "Setting timestamp of ${jpeg_file} to ${heic_date}"
            touch --reference="${heic_file}" "${jpeg_file}"
         else
            log_debug "Time stamps match. Adjustment not required"
         fi
      fi
   done
   IFS="${save_ifs}"
}

remove_recently_deleted_accompanying_files()
{
   IFS=$'\n'
   log_info "Deleting 'Recently Deleted' accompanying files (.JPG/_HEVC.MOV)..."
   for heic_file in $(grep "Deleted /" /tmp/icloudpd/icloudpd_sync.log | grep ".HEIC" | cut --delimiter " " --fields 9-)
   do
      heic_file_clean="${heic_file/!/}"
      jpeg_file_clean="${heic_file_clean%.HEIC}.JPG"
      if [ "${jpeg_path}" ]
      then
         jpeg_file_clean="${jpeg_file_clean/${download_path}/${jpeg_path}}"
      fi
      if [ -f "${jpeg_file_clean}" ]
      then
         log_debug "Deleting ${jpeg_file_clean}"
         rm -f "${jpeg_file_clean}"
      fi
      if [ -f "${heic_file_clean%.HEIC}_HEVC.MOV" ]
      then
         log_debug "Deleting ${heic_file_clean%.HEIC}_HEVC.MOV"
         rm -f "${heic_file_clean%.HEIC}_HEVC.MOV"
      fi
   done
   log_info "Deleting 'Recently Deleted' accompanying files complete"
   IFS="${save_ifs}"
}

remove_empty_directories()
{
   log_info "Deleting empty directories from ${download_path}..."
   find "${download_path}" -type d -empty -delete
   log_info "Deleting empty directories complete"
   if [ "${jpeg_path}" ]
   then
      log_debug "Deleting empty directories from ${jpeg_path}..."
      find "${jpeg_path}" -type d -empty -delete
      log_info "Deleting empty directories complete"
   fi
}

send_notification()
{
   local notification_classification notification_event notification_prority notification_message notification_result notification_files_preview_count notification_files_preview_type notification_files_preview_text
   notification_classification="${1}"
   notification_event="${2}"
   notification_prority="${3}"
   notification_message="${4}"
   notification_files_preview_count="${5}"
   notification_files_preview_type="${6}"
   notification_files_preview_text="${7}"
   notification_wecom_title="${8}"
   notification_wecom_digest="${9}"

   if [ "${notification_classification}" = "startup" ]
   then
      notification_icon="\xE2\x96\xB6"
      # 启动成功通知封面/Image for Startup success
      thumb_media_id="$media_id_startup"
   elif [ "${notification_classification}" = "remotesync" ]
   then
      notification_icon="\xE2\x96\xB6"
      # 启动成功通知封面/Image for Startup success
      thumb_media_id="$media_id_startup"
   elif [ "${notification_classification}" = "downloaded files" ]
   then
      notification_icon="\xE2\x8F\xAC"
      # 下载通知封面/Image for downloaded files
      thumb_media_id="$media_id_download"
   elif [ "${notification_classification}" = "cookie expiration" ]
   then
      notification_icon="\xF0\x9F\x9A\xA9"
      # cookie即将过期通知封面/Image for cookie expiration
      thumb_media_id="$media_id_expiration"
   elif [ "${notification_classification}" = "deleted files" ]
   then
      notification_icon="\xE2\x9D\x8C"
      # 删除文件通知封面/Image for deleted files
      thumb_media_id="$media_id_delete"
   elif [ "${notification_classification}" = "failure" ] || [ "${notification_classification}" = "cookie expired" ]
   then
      notification_icon="\xF0\x9F\x9A\xA8"
      # 同步失败、cookiey已过期通知封面/Image for cookie expired or failure
      thumb_media_id="$media_id_warning"
   fi
   if [ "${notification_type}" ]
   then
      log_info "Sending ${notification_type} ${notification_classification} notification"
   fi
   if [ "${notification_type}" = "Prowl" ]
   then
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "${notification_url}"  \
         --form apikey="${prowl_api_key}" \
         --form application="${notification_title}" \
         --form event="${notification_event}" \
         --form priority="${notification_prority}" \
         --form description="${notification_message}")"
      curl_exit_code="$?"
   elif [ "${notification_type}" = "Pushover" ]
   then
      if [ "${notification_prority}" = "2" ]
      then
         notification_prority=1
      fi
      if [ "${notification_files_preview_count}" ]
      then
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
      curl_exit_code="$?"
   elif [ "${notification_type}" = "Telegram" ]
   then
      if [ "${notification_files_preview_count}" ]
      then
         telegram_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message//_/\\_}\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\n${notification_files_preview_text//_/\\_}")"
      else
         telegram_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message//_/\\_}")"
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
         --data chat_id="${telegram_chat_id}" \
         --data parse_mode="markdown" \
         --data disable_notification="${telegram_disable_notification:=false}" \
         --data text="${telegram_text}")"
      curl_exit_code="$?"
      unset telegram_disable_notification
   elif [ "${notification_type}" = "openhab" ]
   then
      webhook_payload="$(echo -e "${notification_title} - ${notification_message}")"
      notification_result="$(curl -X 'PUT' --silent --output /dev/null --write-out "%{http_code}" "${notification_url}" \
         --header 'content-type: text/plain' \
         --data "${webhook_payload}")"
      curl_exit_code="$?"
   elif [ "${notification_type}" = "Webhook" ]
   then
      webhook_payload="$(echo -e "${notification_title} - ${notification_message}")"
      if [ "${webhook_insecure}" = true ]
      then
         notification_result="$(curl --silent --insecure --output /dev/null --write-out "%{http_code}" "${notification_url}" \
            --header 'content-type: application/json' \
            --data "{ \"${webhook_body}\" : \"${webhook_payload}\" }")"
      else
         notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "${notification_url}" \
            --header 'content-type: application/json' \
            --data "{ \"${webhook_body}\" : \"${webhook_payload}\" }")"
      fi
      curl_exit_code="$?"
   elif [ "${notification_type}" = "Discord" ]
   then
      if [ "${notification_files_preview_count}" ]
      then
         discord_text="${notification_message}\\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\\n${notification_files_preview_text//$'\n'/'\n'}"
      else
         discord_text="$(echo -e "${notification_message}")"
      fi
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
         --header 'content-type: application/json' \
         --data "{ \"username\" : \"${notification_title}\" , \"avatar_url\" : \"https://raw.githubusercontent.com/Womabre/-unraid-docker-templates/master/images/photos_icon_large.png\" , \"embeds\" : [ { \"author\" : { \"name\" : \"${notification_event}\" } , \"color\" : 2061822 , \"description\": \"${discord_text}\" } ] }")"
      curl_exit_code="$?"
   elif [ "${notification_type}" = "Dingtalk" ]
   then
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
         --header 'Content-Type: application/json' \
         --data "{'msgtype': 'markdown','markdown': {'title':'${notification_title}','text':'## ${notification_title}\n${notification_message}'}}")"
      curl_exit_code="$?"
   elif [ "${notification_type}" = "IYUU" ]
   then
      if [ "${notification_files_preview_count}" ]
      then
         iyuu_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\n${notification_files_preview_text//_/\\_}")"
      else
         iyuu_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}")"
      fi
      if [ "${fake_user_agent}" = true ]
      then
         notification_result="$(curl --silent --user-agent "${curl_user_agent}" --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
            --data text="${notification_title}" \
            --data desp="${iyuu_text}")"
      else
         notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST "${notification_url}" \
            --data text="${notification_title}" \
            --data desp="${iyuu_text}")"
      fi
      curl_exit_code="$?"
   elif [ "${notification_type}" = "WeCom" ]
   then
      if [ "$(date +'%s')" -ge "$(date +'%s' -d "${wecom_token_expiry}")" ]
      then
         log_warning "${notification_type} token has expired"
         unset wecom_token
      fi
      if [ -z "${wecom_token}" ]
      then
         log_warning "Obtaining new ${notification_type} token..."
         if [ "${fake_user_agent}" = true ]
         then
            wecom_token="$(/usr/bin/curl --silent --user-agent "${curl_user_agent}" --get "${wecom_token_url}" | awk -F\" '{print $10}')"
         else
            wecom_token="$(/usr/bin/curl --silent --get "${wecom_token_url}" | awk -F\" '{print $10}')"
         fi
         wecom_token_expiry="$(date --date='2 hour')"
         notification_url="${wecom_base_url}/cgi-bin/message/send?access_token=${wecom_token}"
         log_info "${notification_type} token: ${wecom_token}"
         log_info "${notification_type} token expiry time: $(date -d "${wecom_token_expiry}")"
         log_info "${notification_type} notification URL: ${notification_url}"
      fi
      # 结束时间、下次同步时间
      syn_end_time="$(date '+%H:%M:%S')"
      syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
      if [ "${notification_files_preview_count}" ]
      then
         log_info "Attempting creating preview count message body"
         if [ "${icloud_china}" = false ]
         then
            wecom_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}\nMost recent ${notification_files_preview_count} ${notification_files_preview_type} files:\n${notification_files_preview_text//_/\\_}")"
         else
            notification_files_preview_text="${notification_files_preview_text//$'\n'/'<br/>'}"
            wecom_text="$(echo -e "<font style="line-height:1.5"><center><b><big><big>同步日志</big></big></b></font></center><center><b>${notification_message}</b></center><center>···················  <small>最近 ${notification_files_preview_count} 条${notification_files_preview_type}记录如下</small>  ····················</center><code><small>${notification_files_preview_text}</small></code><center>···················  <small>下次同步时间为 ${syn_next_time}</small>  ··················</center>")"
         fi
      else
         log_info "Attempting creating message body"
         if [ "${icloud_china}" = false ]
         then
            wecom_text="$(echo -e "${notification_icon} *${notification_title}*\n${notification_message}")"
         else
            wecom_text="$(echo -e "${notification_message}")"
         fi
      fi
      log_info "Attempting send..."
      if [ "${fake_user_agent}" = true ]
      then
         notification_result="$(curl --silent --user-agent "${curl_user_agent}" --output /dev/null --write-out "%{http_code}" --data-ascii "{\"touser\":\"${touser}\",\"msgtype\":\"mpnews\",\"agentid\":\"${agentid}\",\"mpnews\":{\"articles\":[{\"title\":\"${notification_wecom_title}\",\"thumb_media_id\":\"${thumb_media_id}\",\"author\":\"${syn_end_time}\",\"content_source_url\":\"${content_source_url}\",\"content\":\"${wecom_text}\",\"digest\":\"${notification_wecom_digest}\"}]},\"safe\":\"0\",\"enable_id_trans\":\"0\",\"enable_duplicate_check\":\"0\",\"duplicate_check_interval\":\"1800\"}" --url "${notification_url}")"
      else
         notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" --data-ascii "{\"touser\":\"${touser}\",\"msgtype\":\"mpnews\",\"agentid\":\"${agentid}\",\"mpnews\":{\"articles\":[{\"title\":\"${notification_wecom_title}\",\"thumb_media_id\":\"${thumb_media_id}\",\"author\":\"${syn_end_time}\",\"content_source_url\":\"${content_source_url}\",\"content\":\"${wecom_text}\",\"digest\":\"${notification_wecom_digest}\"}]},\"safe\":\"0\",\"enable_id_trans\":\"0\",\"enable_duplicate_check\":\"0\",\"duplicate_check_interval\":\"1800\"}" --url "${notification_url}")"
      fi
      curl_exit_code="$?"
      log_info "Send result: ${notification_result}"
   elif [ "${notification_type}" = "Gotify" ]
   then
      notification_result="$(curl --silent --output /dev/null --write-out "%{http_code}" "${notification_url}"  \
         -F "title=${notification_title}" \
         -F "message=${notification_message}")"
      curl_exit_code="$?"
   elif [ "${notification_type}" = "Bark" ]
   then
      if [ "${notification_files_preview_count}" ]
      then
	      notification_files_preview_text="$(echo "${notification_files_preview_text}" | tr '\n' ',')"
         bark_text="$(echo -e "${notification_icon} ${notification_message} Most recent ${notification_files_preview_count} ${notification_files_preview_type} files: ${notification_files_preview_text}")"
      else
         bark_text="$(echo -e "${notification_icon} ${notification_message}")"
      fi
      notification_result="$(curl --location --silent --output /dev/null --write-out "%{http_code}" "http://${bark_server}/push" \
         -H 'Content-Type: application/json; charset=utf-8' \
         -d "{ \"device_key\": \"${bark_device_key}\", \"title\": \"${notification_title}\", \"body\": \"${bark_text}\", \"category\": \"category\" }")"
      curl_exit_code="$?"
   elif [ "${notification_type}" = "msmtp" ]
   then
      if [ "${notification_files_preview_count}" ]
      then
	      notification_files_preview_text="$(echo "${notification_files_preview_text}" | tr '\n' ',')"
         mail_text="$(echo -e "${notification_icon} ${notification_message} Most recent ${notification_files_preview_count} ${notification_files_preview_type} files: ${notification_files_preview_text}")"
      else
         mail_text="$(echo -e "${notification_icon} ${notification_message}")"
      fi
      printf "Subject: $notification_message\n\n$mail_text" | msmtp --host=$msmtp_host --port=$msmtp_port --user=$msmtp_user --passwordeval="echo -n $msmtp_pass" --from=$msmtp_from --auth=on --tls=$msmtp_tls "$msmtp_args" -- "$msmtp_to"
   fi
   if [ "${notification_type}" ] && [ "${notification_type}" != "msmtp" ]
   then
      if [ "${notification_result:0:1}" -eq 2 ]
      then
         log_debug "${notification_type} ${notification_classification} notification sent successfully"
      else
         log_error "${notification_type} ${notification_classification} notification failed with http status code: ${notification_result} and curl exit code: ${curl_exit_code}"
         if [ "${notification_result}" = "000" ] && [ "${curl_exit_code}" = "6" ]
         then
            log_error " - HTTP status code '000' and curl exit code '6' means it cannot connect to the server. Please check your network settings"
         else
            if [ "${debug_logging}" != true ]
            then
               log_error "Please set debug_logging=true in your icloudpd.conf file then reproduce the error"
               log_error "***** Once you have captured this log file, please post it along with a description of your problem, here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
            else
               log_error "***** Please post the above debug log, along with a description of your problem, here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
            fi
         fi
         sleep 120
         exit 1
      fi
   fi
}

command_line_builder()
{
   local size
   command_line="--directory ${download_path} --cookie-directory /config --domain ${auth_domain} --username ${apple_id} --no-progress-bar"
   if [ "${photo_size}" = "original" ] || [ "${photo_size}" = "medium" ] || [ "${photo_size}" = "thumb" ] || [ "${photo_size}" = "adjusted" ] || [ "${photo_size}" = "alternative" ]
   then
      command_line="${command_line} --size ${photo_size}"
   else
      if [ "${photo_size}" ]
      then
         SAVE_IFS="$IFS"
         IFS=","
         for size in ${photo_size}
         do
            if [ "${size}" = "original" ] || [ "${size}" = "medium" ] || [ "${size}" = "thumb" ] || [ "${size}" = "adjusted" ] || [ "${size}" = "alternative" ]
            then
               log_debug "Adding photo size ${size} to size types"
               command_line="${command_line} --size ${size}"
            else
               log_warning "Photo size ${size} not recognised, disregarding"
            fi
         done
         IFS="$SAVE_IFS"
      else
         log_warning "Photo size is not specified, original will be downloaded by default"
      fi
   fi
   if [ "${set_exif_datetime}" != false ]
   then
      command_line="${command_line} --set-exif-datetime"
   fi
   if [ "${keep_unicode}" != false ]
   then
      command_line="${command_line} --keep-unicode-in-filenames ${keep_unicode}"
   fi
   if [ "${live_photo_mov_filename_policy}" != "suffix" ]
   then
      command_line="${command_line} --live-photo-mov-filename-policy ${live_photo_mov_filename_policy}"
   fi
   if [ "${align_raw}" != "as-is" ]
   then
      command_line="${command_line} --align-raw ${align_raw}"
   fi
   if [ "${file_match_policy}" != "name-size-dedup-with-suffix" ]
   then
      command_line="${command_line} --file-match-policy ${file_match_policy}"
   fi
   if [ "${auto_delete}" != false ]
   then
      command_line="${command_line} --auto-delete"
   elif [ "${delete_after_download}" != false ]
   then
      command_line="${command_line} --delete-after-download"
   fi
   if [ "${keep_icloud_recent_only}" = true ] && [ "${keep_icloud_recent_days}" ]
   then
      command_line="${command_line} --keep-icloud-recent-days ${keep_icloud_recent_days}"
   fi
   if [ "${skip_live_photos}" = false ]
   then
      if [ "${live_photo_size}" != "original" ]
      then
         command_line="${command_line} --live-photo-size ${live_photo_size}"
      fi
   else
      command_line="${command_line} --skip-live-photos"
   fi
   if [ "${skip_videos}" != false ]
   then
      command_line="${command_line} --skip-videos"
   fi
   if [ -z "${photo_album}" ] && [ -z "${photo_library}" ]
   then
      command_line="${command_line} --folder-structure ${folder_structure}"
   fi
   if [ "${until_found}" ]
   then
      command_line="${command_line} --until-found ${until_found}"
   fi
   if [ "${recent_only}" ]
   then
      command_line="${command_line} --recent ${recent_only}"
   fi
}

synchronise_user()
{
   log_info "Sync user: ${user}"
   if [ "${synchronisation_delay}" -ne 0 ]
   then
      log_info "Delay for ${synchronisation_delay} minutes"
      sleep "${synchronisation_delay}m"
   fi
   while true
   do
      synchronisation_start_time="$(date +'%s')"
      log_info "Synchronisation starting at $(date +%H:%M:%S -d "@${synchronisation_start_time}")"
      source <(grep debug_logging "${config_file}")
      chown -R "${user_id}:${group_id}" "/config"
      check_keyring_exists
      if [ "${authentication_type}" = "MFA" ]
      then
         log_debug "Check MFA Cookie"
         valid_mfa_cookie=false
         while [ "${valid_mfa_cookie}" = false ]
         do
            check_multifactor_authentication_cookie
         done
      fi
      check_mount
      if [ "${skip_check}" = false ]
      then
         check_files
      else
         check_exit_code=0
         check_files_count=1
      fi
      if [ "${check_exit_code}" -eq 0 ]
      then
         if [ "${check_files_count}" -gt 0 ]
         then
            log_debug "Starting download of new files for user: ${user}"
            synchronisation_time="$(date +%s -d '+15 minutes')"
            log_debug "Downloading new files using password stored in keyring file..."
            >/tmp/icloudpd/icloudpd_download_error
            IFS=$'\n'
            if [ "${photo_album}" ]
            then
               log_debug "Starting Photo Album download"
               download_albums
            elif [ "${photo_library}" ]
            then
               log_debug "Starting Photo Library download"
               download_libraries
            else
               log_debug "Starting Photo download"
               download_photos
            fi
            download_exit_code="$(cat /tmp/icloudpd/icloudpd_download_exit_code)"
            if [ "${download_exit_code}" -gt 0 ] || [ -s /tmp/icloudpd/icloudpd_download_error ]
            then
               log_error "Failed to download new files"
               log_error " - Can you log into ${icloud_domain} without receiving pop-up notifications?"
               log_error "Error debugging info:"
               log_error "$(cat /tmp/icloudpd/icloudpd_download_error)"
               if [ "${debug_logging}" != true ]
               then
                  log_error "Please set debug_logging=true in your icloudpd.conf file then reproduce the error"
                  log_error "***** Once you have captured this log file, please post it along with a description of your problem, here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
               else
                  log_error "***** Please post the above debug log, along with a description of your problem, here: https://github.com/boredazfcuk/docker-icloudpd/issues *****"
               fi
               if [ "${icloud_china}" = false ]
               then
                  send_notification "failure" "iCloudPD container failure" "1" "iCloudPD failed to download new files for Apple ID: ${apple_id}"
               else
                  # 结束时间、下次同步时间
                  syn_end_time="$(date '+%H:%M:%S')"
                  syn_next_time="$(date +%H:%M:%S -d "${synchronisation_interval} seconds")"
                  send_notification "failure" "iCloudPD container failure" "1" "从 iCloud 图库下载新照片失败，将在 ${syn_next_time} 再次尝试" "" "" "" "下载 ${name} 的 iCloud 图库新照片失败" "将在 ${syn_next_time} 再次尝试"
               fi
            else
               if [ "${download_notifications}" ]
               then
                  downloaded_files_notification
               fi
               if [ "${synology_photos_app_fix}" = true ]
               then
                  synology_photos_app_fix
               fi
               if [ "${convert_heic_to_jpeg}" != false ]
               then
                  log_info "Convert HEIC files to JPEG"
                  convert_downloaded_heic_to_jpeg
               fi
               if [ "${sideways_copy_videos}" = true ]
               then
                  log_info "Copy videos sideways to: ${video_path}"
                  sideways_copy_videos
               fi
               if [ "${nextcloud_upload}" = true ]
               then
                  nextcloud_sync
               fi
               if [ "${delete_notifications}" ]
               then
                  deleted_files_notification
               fi
               if [ "${delete_accompanying}" = true ] && [ "${folder_structure}" != "none" ] && [ "${set_exif_datetime}" = false ]
               then
                  remove_recently_deleted_accompanying_files
               fi
               if [ "${delete_empty_directories}" = true ] && [ "${folder_structure}" != "none" ]
               then
                  remove_empty_directories
               fi
               # set_owner_and_permissions_downloads
               log_info "Synchronisation complete for ${user}"
               if [ "${notification_type}" ] && [ "${remote_sync_complete_notification}" = true ]
               then
                  send_notification "remotesync" "iCloudPD remote synchronisation complete" "0" "iCloudPD has completed a remote synchronisation request for Apple ID: ${apple_id}"
                  unset remote_sync_complete_notification
               fi
            fi
            login_counter=$((login_counter + 1))
         fi
      fi
      check_web_cookie
      log_info "Web cookie expires: ${web_cookie_expire_date/ / @ }"
      if [ "${authentication_type}" = "MFA" ]
      then
         display_multifactor_authentication_expiry
      fi
      log_debug "iCloud login counter = ${login_counter}"
      synchronisation_end_time="$(date +'%s')"
      log_info "Synchronisation ended at $(date +%H:%M:%S -d "@${synchronisation_end_time}")"
      log_info "Total time taken: $(date +%H:%M:%S -u -d "@$((synchronisation_end_time - synchronisation_start_time))")"
      if [ "${single_pass:=false}" = true ]
      then
         log_debug "Single Pass mode set, exiting"
         exit 0
      else
         sleep_time="$((synchronisation_interval - synchronisation_end_time + synchronisation_start_time))"
         if [ "${sleep_time}" -ge "72000" ]
         then
            log_info "Next synchronisation at $(date +%c -d "${sleep_time} seconds")"
         else
            log_info "Next synchronisation at $(date +%H:%M:%S -d "${sleep_time} seconds")"
         fi
         unset check_exit_code check_files_count download_exit_code
         unset new_files
         if [ "${notification_type}" = "Telegram" ] && [ "${telegram_polling}" = true ]
         then
            log_info "Monitoring ${notification_type} for remote commands prefix: ${user}"
            listen_counter=0
            poll_sleep=30
            while [ "${listen_counter}" -lt "${sleep_time}" ]
            do
               if [ "${telegram_polling}" = true ]
               then
                  unset latest_updates latest_update_ids break_while
                  update_count=0
                  telegram_update_id_offset="$(head -1 "${telegram_update_id_offset_file}")"
                  log_debug "Polling Telegram for updates newer than: ${telegram_update_id_offset}"
                  telegram_update_id_offset_inc=$((telegram_update_id_offset + 1))
                  latest_updates="$(curl --request POST --silent --data "allowed_updates=message" --data "offset=${telegram_update_id_offset_inc}" "${telegram_base_url}/getUpdates" | jq .result[])"
                  if [ "${latest_updates}" ]
                  then
                     latest_update_ids="$(echo "${latest_updates}" | jq -r '.update_id')"
                  fi
                  if [ "${latest_update_ids}" ]
                  then
                     update_count="$(echo "${latest_update_ids}" | wc --lines)"
                     log_debug "Updates to process: ${update_count}"
                     if [ "${update_count}" -gt 0 ]
                     then
                        for latest_update in ${latest_update_ids}
                        do
                           log_debug "Processing update: ${latest_update}"
                           check_update="$(echo "${latest_updates}" | jq ". | select(.update_id == ${latest_update}).message")"
                           check_update_text="$(echo "${check_update}" | jq -r .text)"
                           check_update_text_lc="$(echo "${check_update_text}" | tr '[:upper:]' '[:lower:]')"
                           log_debug "New message received: ${check_update_text}"
                           user_lc="$(echo "${user}" | tr '[:upper:]' '[:lower:]')"
                           if [ "${check_update_text_lc}" = "${user_lc}" ]
                           then
                              break_while=true
                              log_debug "Remote sync message match: ${check_update_text}"
                           elif  [ "${check_update_text_lc}" = "${user_lc} auth" ]
                           then
                              log_debug "Remote authentication message match: ${check_update_text}"
                              if [ "${icloud_china}" = false ]
                              then
                                 send_notification "remotesync" "iCloudPD remote synchronisation initiated" "0" "iCloudPD has detected a remote authentication request for Apple ID: ${apple_id}"
                              else
                                 send_notification "remotesync" "iCloudPD remote synchronisation initiated" "0" "iCloudPD将以Apple ID: ${apple_id}发起身份验证"
                              fi
			                     rm "/config/${cookie_file}" "/config/${cookie_file}.session"
                              log_debug "Starting remote authentication process"
                              /usr/bin/expect /opt/authenticate.exp &
                              poll_sleep=3
                           elif [ "$(expr match "${check_update_text_lc}" "^${user_lc} [0-9][0-9][0-9][0-9][0-9][0-9]$" >/dev/null; echo $?)" -eq 0 ]
                           then
                              mfa_code="$(echo "${check_update_text}" | awk '{print $2}')"
                              echo "${mfa_code}" > /tmp/icloudpd/expect_input.txt
                              listen_counter=$((listen_counter+2))
                              # additional sleeps mean sync time slips each time time a sync or auth is performed
                              # adding same amount of time to listen counter should prevent this from occurring
                              sleep 2
                              unset mfa_code
                              poll_sleep=30
                           elif [ "$(expr match "${check_update_text_lc}" "^${user_lc} [a-z]$" >/dev/null; echo $?)" -eq 0 ]
                           then
                              sms_choice="$(echo "${check_update_text}" | awk '{print $2}')"
                              echo "${sms_choice}" > /tmp/icloudpd/expect_input.txt
                              listen_counter=$((listen_counter+2))
                              # Same again
                              sleep 2
                              unset sms_choice
                              poll_sleep=3
                           else
                              log_debug "Ignoring message: ${check_update_text}"
                              poll_sleep=30
                           fi
                        done
                        echo -n "${latest_update}" > "${telegram_update_id_offset_file}"
                        if [ "${break_while}" ]
                        then
                           log_debug "Remote sync initiated"
                           if [ "${icloud_china}" = false ]
                           then
                              send_notification "remotesync" "iCloudPD remote synchronisation initiated" "0" "iCloudPD has detected a remote synchronisation request for Apple ID: ${apple_id}"
                              remote_sync_complete_notification=true
                           else
                              send_notification "remotesync" "iCloudPD remote synchronisation initiated" "0" "启动成功，开始同步当前 Apple ID 中的照片" "" "" "" "开始同步 ${name} 的 iCloud 图库" "Apple ID: ${apple_id}"
                           fi
                              poll_sleep=30
                           break
                        fi
                     fi
                  fi
               fi
               listen_counter=$((listen_counter+poll_sleep))
               # additional sleeps mean sync time slips each time time a sync or auth is performed
               # adding same amount of time to listen counter should prevent this from occurring
               sleep "${poll_sleep}"
            done
         else
            sleep "${sleep_time}"
         fi
      fi
   done
}

sanitise_launch_parameters()
{
   if [ "${script_launch_parameters}" ]
   then
      case "$(echo "${script_launch_parameters}" | tr '[:upper:]' '[:lower:]')" in
         "--initialise"|"--initialize"|"--init"|"--remove-keyring"|"--convert-all-heics"|"--remove-all-jpgs"|"--force-convert-all-heics"|"--force-convert-all-mnt-heics"|"--correct-jpeg-time-stamps"|"--upload-library-to-nextcloud"|"--sideways-copy-all-videos"|"--list-albums"|"--list-libraries"|"--enable-debugging"|"--disable-debugging")
            log_info "Script launch parameters: ${script_launch_parameters}"
         ;;
         *)
            log_warning "Ignoring invalid launch parameter specified: ${script_launch_parameters}"
            log_warning "Please do not specify the above parameter when launching the container. Continuing in 2 minutes"
            sleep 120
            unset script_launch_parameters
         ;;
      esac
   fi
}

enable_debug_logging()
{
   sed -i 's/debug_logging=.*/debug_logging=true/' "${config_file}"
   log_info "Debug logging enabled"
}

disable_debug_logging()
{
   sed -i 's/debug_logging=.*/debug_logging=false/' "${config_file}"
   log_info "Debug logging disabled"
}

##### Script #####
script_launch_parameters="${1}"
if [ "${2}" ]
then
   log_warning "Only a single command line parameter is supported at this time. Only processing: ${script_launch_parameters}"
fi
case  "$(echo "${script_launch_parameters}" | tr '[:upper:]' '[:lower:]')" in
   "--initialise"|"--initialize"|"--init")
      initialise_container=true
    ;;
   "--remove-keyring")
      delete_password=true
    ;;
   "--convert-all-heics")
      convert_all_heics=true
   ;;
   "--remove-all-jpgs")
      remove_all_jpgs=true
   ;;
   "--force-convert-all-heics")
      force_convert_all_heics=true
   ;;
   "--force-convert-all-mnt-heics")
      force_convert_all_mnt_heics=true
   ;;
   "--correct-jpeg-time-stamps")
      correct_jpeg_time_stamps=true
   ;;
   "--enable-debugging")
      enable_debugging=true
   ;;
   "--disable-debugging")
      disable_debugging=true
   ;;
   "--upload-library-to-nextcloud")
      nextcloud_upload_library=true
   ;;
   "--sideways-copy-all-videos")
      sideways_copy_all_videos=true
   ;;
   "--help")
      "$(which more)" "/opt/CONFIGURATION.md"
      exit 0
   ;;
   "--list-albums")
      list_albums=true
   ;;
   "--list-libraries")
      list_libraries=true
   ;;
   *)
   ;;
esac

initialise_script
sanitise_launch_parameters
if [ "${delete_password:=false}" = true ]
then
   log_info "Deleting password from keyring"
   delete_password
   log_info "Password deletion complete"
   exit 0
fi
configure_password
if [ "${initialise_container:=false}" = true ]
then
   log_info "Starting container initialisation"
   generate_cookie
   log_info "Container initialisation complete"
   exit 0
elif [ "${enable_debugging:=false}" = true ]
then
   log_info "Enabling debug logging"
   enable_debug_logging
   exit 0
elif [ "${disable_debugging:=false}" = true ]
then
   log_info "Disabling debug logging"
   disable_debug_logging
   exit 0
elif [ "${convert_all_heics:=false}" = true ]
then
   log_info "Converting all HEICs to JPG"
   convert_all_heic_files
   # set_owner_and_permissions_downloads
   log_info "HEIC to JPG conversion complete"
   exit 0
elif [ "${remove_all_jpgs:=false}" = true ]
then
   log_info "Forcing removal of JPG files if accompanying HEIC exists"
   remove_all_jpeg_files
   # set_owner_and_permissions_downloads
   log_info "Forced removal of JPG files if accompanying HEIC exists complete"
   exit 0
elif [ "${force_convert_all_heics:=false}" = true ]
then
   log_info "Forcing HEIC to JPG conversion"
   force_convert_all_heic_files
   # set_owner_and_permissions_downloads
   log_info "Forced HEIC to JPG conversion complete"
   exit 0
elif [ "${force_convert_all_mnt_heics:=false}" = true ]
then
   log_info "Forcing HEIC to JPG conversion of all files in mount path"
   force_convert_all_mnt_heic_files
   # set_owner_and_permissions_downloads
   log_info "Forced HEIC to JPG conversion of all files in mount path complete"
   exit 0
elif [ "${correct_jpeg_time_stamps:=false}" = true ]
then
   log_info "Correcting timestamps for JPEG files in ${download_path}"
   correct_jpeg_timestamps
   log_info "JPEG timestamp correction complete"
   exit 0
elif [ "${nextcloud_upload_library:=false}" = true ]
then
   log_info "Uploading library to Nextcloud"
   nextcloud_upload_library
   log_info "Uploading library to Nextcloud complete"
   exit 0

elif [ "${sideways_copy_all_videos:=false}" = true ]
then
   log_info "Copying all videos sideways"
   sideways_copy_all_videos
   log_info "Sideways copying of all videos complete"
   exit 0
elif [ "${list_albums:=false}" = true ]
then
   list_albums
   exit 0
elif [ "${list_libraries:=false}" = true ]
then
   list_libraries
   exit 0
fi
check_mount
# set_owner_and_permissions_config
command_line_builder
check_keyring_exists
synchronise_user