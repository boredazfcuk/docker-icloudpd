#!/bin/ash

##### Functions #####
Initialise(){
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** boredazfcuk/icloudpd container for icloud_photo_downloader started *****"
   cookie="$(echo -n "${apple_id//[^a-zA-Z0-9]/}" | tr '[:upper:]' '[:lower:]')"
   if [ -t 0 ]; then interactive_session="True"; fi
   if [ ! -d "/tmp/icloudpd" ]; then mkdir -p "/tmp/icloudpd"; fi
   if [ -z "${apple_password}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID Password not set - exiting"; sleep 120; exit 1; fi
   if [ -z "${apple_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID not set - exiting"; sleep 120; exit 1; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local user: ${user:=user}:${user_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local group: ${group:=group}:${group_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID: ${apple_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID Password: ${apple_password}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Authentication_type: ${authentication_type:=2FA}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie path: ${config_dir}/${cookie}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     iCloud directory: /home/${user}/iCloud"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Folder structure: ${folder_structure:={:%Y/%m/%d\}}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Directory permissions: ${directory_permissions}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     File permissions: ${file_permissions}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation interval: ${synchronisation_interval:=43200}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Time zone: ${TZ:=UTC}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Additional command line options: ${command_line_options}"

   if [ "${notification_type}" ]; then
      if [ -z "${prowl_api_key}" ] && [ -z "${pushbullet_api_key}" ] && [ -z "${telegram_token}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  ${notification_type} notifications enabled, but API key/token not set - disabling notifications"
         unset notification_type
      else
         if [ "${notification_type}" = "Prowl" ] && [ "${prowl_api_key}" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notifications enabled"
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Notification period: ${notification_days=7}"
            notification_url="https://api.prowlapp.com/publicapi/add" 
            Notify "startup" "iCloudPD container started" "0" "iCloud_Photos_Downloader container now starting"
         elif  [ "${notification_type}" = "Pushbullet" ] && [ "${pushbullet_api_key}" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notifications enabled"
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Notification period: ${notification_days=7}"
            notification_url="https://pushbullet.weks.net/publicapi/add"
            Notify "startup" "iCloudPD container started" "0" "iCloud_Photos_Downloader container now starting"
         elif [ "${notification_type}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notifications enabled"
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} token ${telegram_token}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} chat id ${telegram_chat_id}"
            notification_url="https://api.telegram.org/bot${telegram_token}/sendMessage"
            telegram_text="$(echo -e "iCloudPD:\nContainer started for iCloud_Photos_Downloader")"
            URLEncode "${telegram_text}"
            Notify "startup" "${encoded_string}"
         else
            echo "$(date '+%Y-%m-%d %H:%M:%S') WARINING ${notification_type} notifications enabled, but configured incorrectly - disabling notifications"
            unset notification_type prowl_api_key pushbullet_api_key telegram_token telegram_chat_id
         fi
      fi
   fi
}

CreateGroup(){
   if [ -z "$(getent group ${group} | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Group ID available, creating group"
      addgroup -g "${group_id}" "${group}"
   elif [ ! "$(getent group "${group}" | cut -d: -f3)" = "${group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group ID already in use - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${user}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User ID available, creating user"
      adduser -s /bin/ash -D -G "${group}" -u "${user_id}" "${user}" -h "/home/$user"
   elif [ ! "$(getent passwd "${user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User ID already in use - exiting"
      exit 1
   fi
}

Generate2FACookie(){
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on config directory, if required"
   find "${config_dir}" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on config directory, if required"
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} +
   if [ -f "${config_dir}/${cookie}" ]; then
      rm "${config_dir}/${cookie}"
   fi
   su "${user}" -c "/usr/bin/icloudpd --username \"${apple_id}\" --password \"${apple_password}\" --cookie-directory \"${config_dir}\" 2>/dev/null"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie generated. Sync should now be successful"
   exit 0
}

CheckMount(){
   while [ ! -f "/home/${user}/iCloud/.mounted" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Destination volume not mounted - retry in 5 minutes"
      sleep 300
   done
}

PrepareDownloadDirectory(){
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set owner, ${user}, on iCloud directory, if required"
   find "/home/${user}/iCloud" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set group, ${group}, on iCloud directory, if required"
   find "/home/${user}/iCloud" ! -group "${group}" -exec chgrp "${group}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct owner on icloudpd temp directory, if required"
   find "/tmp/icloudpd" ! -user "${user}" -exec chown "${user}" {} +
   echo  "$(date '+%Y-%m-%d %H:%M:%S') INFO     Correct group on icloudpd temp directory, if required"
   find "/tmp/icloudpd" ! -group "${group}" -exec chgrp "${group}" {} +
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
   fi
}

Display2FAExpiry(){
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie expires: ${twofa_expire_date/ / @ }"
      if [ "${days_remaining}" -lt "${notification_days}" ]; then
         if [ "${syncronisation_time}" -gt "${next_notification_time:=$(date +%s)}" ]; then
            if [ "${days_remaining}" -eq 1 ]; then
               echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Final day before two factor authentication cookie expires - Please reinitialise now"
               if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet" ]; then
                  Notify "cookie expiration" "2FA Cookie Expiriation" "2" "Final day before two factor authentication cookie expires - Please reinitialise now"
                  next_notification_time="$(date +%s -d "+24 hour")"
               fi
            else
               echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Only ${days_remaining} days until two factor authentication cookie expires - Please reinitialise"
               if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet" ]; then
                  Notify "cookie expiration" "2FA Cookie Expiration" "1" "Only ${days_remaining} days until two factor authentication cookie expires - Please reinitialise"
                  next_notification_time="$(date +%s -d "+24 hour")"
               fi
            fi
         fi
      fi
}

URLEncode(){
   local url_to_encode="${1}"
   local string_length="${#url_to_encode}"
   local encoded=""
   local position=0
   local character output
   while [ "${position}" -lt "${string_length}" ]; do
      character="${url_to_encode:$position:1}"
      case "${character}" in
         [-_.~a-zA-Z0-9] ) output="${character}" ;;
                       * ) output="$(echo -n "${character}" | od -An -tx1 | tr ' ' % | tr -d '\n')"
      esac
      encoded="${encoded}${output}"
      position=$((position + 1))
   done
   encoded_string="${encoded}"
}

CheckFiles(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check for new files..."
   check_files="$(/usr/bin/icloudpd --directory "/home/${user}/iCloud" --cookie-directory "${config_dir}" --username "${apple_id}" --password "${apple_password}" --folder-structure "${folder_structure}" --only-print-filenames 1>/tmp/icloudpd/icloudpd_check.log 2>/tmp/icloudpd/icloudpd_check_error.log)"
   check_exit_code=$?
   echo "${check_exit_code}" >/tmp/icloudpd/check_exit_code
   check_files="$(echo -n "${check_files}")"
   check_files_count="$(grep -c ^ /tmp/icloudpd/icloudpd_check.log)"
   if [ "${check_files_count}" -gt 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     New files detected: ${check_files_count}"
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     New files detected: ${check_files_count}"
   fi
}

DownloadedFiles(){
   new_files="$(grep "Downloading /" /tmp/icloudpd/icloudpd_sync.log)"
   new_files_count="$(grep -c "Downloading /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${new_files_count:=0}" -gt 0 ]; then
      if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet}" ]; then
         Notify "downloaded files" "New files detected" "0" "Files downloaded: ${new_files_count}"
      elif [ "${notification_type}" = "Telegram" ]; then
         new_files_preview="$(echo "${new_files}" | awk '{print $5}' | sed -e "s%/home/${user}/iCloud/%%g" | tail -10)"
         new_files_preview_count="$(echo "${new_files_preview}" | wc -l)"
         telegram_new_files_text="$(echo -e "iCloudPD:\nNew files detected: ${new_files_count}\nLast ${new_files_preview_count} file names:\n${new_files_preview}")"
         URLEncode "${telegram_new_files_text}"
         Notify "downloaded files" "${encoded_string}"
      fi
   fi
}

DeletedFiles(){
   deleted_files="$(grep "Deleting /" /tmp/icloudpd/icloudpd_sync.log)"
   deleted_files_count="$(grep -c "Deleting /" /tmp/icloudpd/icloudpd_sync.log)"
   if [ "${deleted_files_count:=0}" -gt 0 ]; then
      if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet}" ]; then
         Notify "deleted files" "Recently deleted files detected" "0" "Files deleted: ${deleted_files_count}"
      elif [ "${notification_type}" = "Telegram" ]; then
         deleted_files_preview="$(echo "${deleted_files}" | awk '{print $5}' | sed -e "s%/home/${user}/iCloud/%%g" -e "s%!$%%g" | tail -10)"
         deleted_files_preview_count="$(echo "${deleted_files_preview}" | wc -l)"
         telegram_deleted_files_text="$(echo -e "iCloudPD:\nDeleted files detected: ${deleted_files_count}\nLast ${deleted_files_preview_count} file names:\n${deleted_files_preview}")"
         URLEncode "${telegram_deleted_files_text}"
         Notify "deleted files" "${encoded_string}"
      fi
   fi
}

ConvertHEIC2JPEG(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Converting HEIC to JPEG"
   for heic_file in $(echo "${new_files}" | grep ".HEIC" | awk '{print $5}'); do
      heif-convert "${heic_file}" "${heic_file/%.HEIC/.JPG}"
   done
}

DeleteHEICJPEGS(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Removing JPEGs of deleted HEIC files"
   for deleted_heic_file in $(echo "${deleted_files}" | grep ".HEIC" | awk '{print $5}' | sed -e "s%!$%%g"); do
      if [ -f "${deleted_heic_file}" ]; then 
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Removing $(rm -v "${deleted_heic_file/%.HEIC/.JPG}")"
      fi
   done
}

Notify(){
   if [ "${notification_type}" = "Prowl" ] || [ "${notification_type}" = "Pushbullet" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sending ${notification_type} ${1} notification"
      curl --silent "${notification_url}"  \
         --form apikey="${notification_api_key}" \
         --form application="iCloud Photo Downloader" \
         --form event="${2}" \
         --form priority="${3}" \
         --form description="${4}" \
         >/dev/null 2>&1 &
         curl_exit_code=$?
      if [ "${curl_exit_code}" -eq 0 ]; then 
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notification sent successfully: \"Event: ${1}\" \"Priority ${2}\" \"Message ${3}\""
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    ${notification_type} notification failed"
         sleep 120
         exit 1
      fi
   elif [ "${notification_type}" = "Telegram" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sending ${notification_type} notification"
      curl --silent --request POST "${notification_url}" \
         --data chat_id="${telegram_chat_id}" \
         --data text="${2}" \
         >/dev/null 2>&1 &
         curl_exit_code=$?
      if [ "${curl_exit_code}" -eq 0 ]; then 
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${notification_type} notification sent successfully"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    ${notification_type} notification failed"
         sleep 120
         exit 1
      fi
   fi
}

SyncUser(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sync user ${user}"
   while :; do
      if [ "${authentication_type}" = "2FA" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check 2FA Cookie"
         valid_twofa_cookie=False
         while [ "${valid_twofa_cookie}" = "False" ]; do Check2FACookie; done
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Check download directory mounted correctly"
      CheckMount
      CheckFiles
      if [ "${check_exit_code}" -gt 0 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Error during new file check - exit code: ${check_exit_code}"
      else
         if [ "${check_files_count}" -gt 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Starting download of ${check_files_count} new files for user: ${user}"
            syncronisation_time="$(date +%s -d '+15 minutes')"
            su "${user}" -c "(/usr/bin/icloudpd --directory /home/${user}/iCloud --cookie-directory ${config_dir} --username ${apple_id} --password ${apple_password} --folder-structure ${folder_structure} ${command_line_options} 2>&1; echo $? >/tmp/icloudpd/download_exit_code) | tee -a /tmp/icloudpd/icloudpd_sync.log"
            download_exit_code="$(cat /tmp/icloudpd/download_exit_code)"
            if [ "${download_exit_code}" -gt 0 ]; then
               echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Error during download - Exit code: ${download_exit_code}"
            else
               DownloadedFiles
               if [ "${convert_heic_to_jpeg}" ]; then
                  echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Convert HEIC files to JPEG"
                  ConvertHEIC2JPEG
               fi
               DeletedFiles
               if [ "${delete_heic_jpegs}" ]; then
                  DeleteHEICJPEGS
               fi
            fi
         else
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     No new files detected. Nothing to download"
         fi
      fi
      CheckWebCookie
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Web cookie expires: ${web_cookie_expire_date/ / @ }"
      if [ "${authentication_type}" = "2FA" ]; then Display2FAExpiry; fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation complete for ${user}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Next syncronisation at $(date +%H:%M -d "${synchronisation_interval} seconds")"
      unset check_exit_code download_exit_code
      unset check_files new_files deleted_files
      unset check_files_count new_files_count deleted_files_count
      unset new_files_preview deleted_files_preview
      unset telegram_new_files_text telegram_deleted_files_text
      sleep "${synchronisation_interval}"
   done
}

##### Script #####
Initialise
CreateGroup
CreateUser
if [ "${interactive_session:=False}" = "True" ]; then Generate2FACookie; fi
CheckMount
PrepareDownloadDirectory
SyncUser