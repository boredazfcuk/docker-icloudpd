#!/bin/ash

log_info()
{
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${1}"
}

log_info_n()
{
   echo -n "$(date '+%Y-%m-%d %H:%M:%S') INFO     ${1}"
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

create_group()
{
   if [ "$(grep -c "^${group}:x:${group_id}:" "/etc/group")" -eq 0 ]
   then
      log_debug "   | Creating minimal /etc/group file"
      {
         echo 'root:x:0:root'
         echo 'tty:x:5:'
         echo 'shadow:x:42:'
      } >/etc/group
      if [ "$(grep -c "^${group}:" "/etc/group")" -eq 1 ]
      then
         log_error "   | Group name, ${group}, already in use. Cannot continue. Halting"
         sleep infinity
      fi
      log_debug "   | Creating group ${group}:${group_id}"
      groupadd --gid "${group_id}" "${group}"
   fi
}

create_user()
{
   if [ "$(grep -c "^${user}:x:${user_id}:${group_id}" "/etc/passwd")" -eq 0 ]
   then
      log_debug "   | Creating minimal /etc/passwd file"
      echo 'root:x:0:0:root:/root:/bin/ash' >/etc/passwd
      log_debug "   | Creating user ${user}:${user_id}"
      useradd --shell /bin/ash --gid "${group_id}" --uid "${user_id}" "${user}" --home-dir "/home/${user}" --badname
   fi
}

set_owner_and_permissions_downloads()
{
   log_info " - Setting owner, group and permissions on: ${download_path}"
   log_debug "   | Set owner"
   find "${download_path}" ! -type l ! -user "${user_id}" ! -path "${ignore_path}" -exec chown "${user_id}" {} +
   log_debug "   | Set group"
   find "${download_path}" ! -type l ! -group "${group_id}" ! -path "${ignore_path}" -exec chgrp "${group_id}" {} +
   log_debug "   | Set ${directory_permissions} permissions on directories"
   find "${download_path}" -type d ! -perm "${directory_permissions}" ! -path "${ignore_path}" -exec chmod "${directory_permissions}" '{}' +
   log_debug "   | Set ${file_permissions} permissions on files"
   find "${download_path}" -type f ! -perm "${file_permissions}" ! -path "${ignore_path}" -exec chmod "${file_permissions}" '{}' +
}

set_owner_and_permissions_jpegs()
{
   log_info " - Setting owner, group and permissions on: ${jpeg_path}"
   log_debug "   | Set owner"
   find "${jpeg_path}" ! -type l ! -user "${user_id}" ! -path "${ignore_path}" -exec chown "${user_id}" {} +
   log_debug "   | Set group"
   find "${jpeg_path}" ! -type l ! -group "${group_id}" ! -path "${ignore_path}" -exec chgrp "${group_id}" {} +
   log_debug "   | Set ${directory_permissions} permissions on directories"
   find "${jpeg_path}" -type d ! -perm "${directory_permissions}" ! -path "${ignore_path}" -exec chmod "${directory_permissions}" '{}' +
   log_debug "   | Set ${file_permissions} permissions on files"
   find "${jpeg_path}" -type f ! -perm "${file_permissions}" ! -path "${ignore_path}" -exec chmod "${file_permissions}" '{}' +
}

set_owner_and_permissions_videos()
{
   log_info " - Setting owner, group and permissions on: ${video_path}"
   log_debug "   | Set owner"
   find "${video_path}" ! -type l ! -user "${user_id}" ! -path "${ignore_path}" -exec chown "${user_id}" {} +
   log_debug "   | Set group"
   find "${video_path}" ! -type l ! -group "${group_id}" ! -path "${ignore_path}" -exec chgrp "${group_id}" {} +
   log_debug "   | Set ${directory_permissions} permissions on directories"
   find "${video_path}" -type d ! -perm "${directory_permissions}" ! -path "${ignore_path}" -exec chmod "${directory_permissions}" '{}' +
   log_debug "   | Set ${file_permissions} permissions on files"
   find "${video_path}" -type f ! -perm "${file_permissions}" ! -path "${ignore_path}" -exec chmod "${file_permissions}" '{}' +
}

set_owner_and_permissions_config()
{
   log_info " - Set owner and group on config directory: /config"
   chown -R "${user_id}:${group_id}" "/config"
   log_info " - Set owner and group on icloudpd temp directory: /tmp/icloudpd"
   chown -R "${user_id}:${group_id}" "/tmp/icloudpd"
}

run_as()
{
   if [ "$(id -u)" = 0 ]
   then
      su "${user}" -s /bin/ash -c "${1}"
   else
      /bin/ash -c "${1}"
   fi
}

##### Start Script #####
log_info "Initialising container..."

# Create the temporary directory
if [ ! -d "/tmp/icloudpd" ]
then
   log_info " - Creating temporary directory"
   if ! mkdir --parents "/tmp/icloudpd"
   then
      log_error "Failed to create temporary directory"
   fi
fi

# Remove pre-existing temporary files
if [ -f "/tmp/icloudpd/icloudpd_check_exit_code" ]
then
   rm "/tmp/icloudpd/icloudpd_check_exit_code"
fi
if [ -f "/tmp/icloudpd/icloudpd_download_exit_code" ]
then
   rm "/tmp/icloudpd/icloudpd_download_exit_code"
fi
if [ -f "/tmp/icloudpd/icloudpd_check_error" ]
then
   rm "/tmp/icloudpd/icloudpd_check_error"
fi
if [ -f "/tmp/icloudpd/icloudpd_download_error" ]
then
   rm "/tmp/icloudpd/icloudpd_download_error"
fi
if [ -f "/tmp/icloudpd/icloudpd_sync.log" ]
then
   rm "/tmp/icloudpd/icloudpd_sync.log"
fi
if [ -f "/tmp/icloudpd/icloudpd_tracert.err" ]
then
   rm "/tmp/icloudpd/icloudpd_tracert.err"
fi

# Create new temporary files
log_info " - Create temporary files"
if ! touch "/tmp/icloudpd/icloudpd_check_exit_code"
then
   log_error "   | Failed to create /tmp/icloudpd/icloudpd_check_exit_code"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
if ! touch "/tmp/icloudpd/icloudpd_download_exit_code"
then
   log_error "   | Failed to create /tmp/icloudpd/icloudpd_download_exit_code"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
if ! touch "/tmp/icloudpd/icloudpd_check_error"
then
   log_error "   | Failed to create /tmp/icloudpd/icloudpd_check_error"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
if ! touch "/tmp/icloudpd/icloudpd_download_error"
then
   log_error "   | Failed to create /tmp/icloudpd/icloudpd_download_error"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
if ! touch "/tmp/icloudpd/icloudpd_sync.log"
then
   log_error "   | Failed to create /tmp/icloudpd/icloudpd_sync.log"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
if ! touch "/tmp/icloudpd/icloudpd_tracert.err"
then
   log_error "   | Failed to create /tmp/icloudpd/icloudpd_tracert.err"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
if ! touch "/tmp/icloudpd/expect_input.txt"
then
   log_error "   | Failed to create /tmp/icloudpd/expect_input.txt"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi

# Push icloudpd version to file so it's a smidgen quicker to load on container restarts/syncs
/opt/icloudpd/bin/icloudpd --version | awk -F, '{print $1}' | sed 's/version://' > /tmp/icloudpd/icloudpd_version
python3 --version | awk '{print $2}' > /tmp/icloudpd/python_version

# Check the config directory exists and create it if it does not
log_info " - Checking configuration file permissions"
if [ ! -d "/config" ]
then
   if ! mkdir /config
   then
      log_error "   | Failed to create configuration directory: /config"
      log_error "   ! Check your volume mount is not read-only. Check NFS/SMB share permissions if mounting to a shared location"
      log_error "   ! Cannot continue. Halting"
      sleep infinity
   fi
fi

# Check the config file exists and create it if it does not
if [ ! -f "${config_file}" ]
then
   if ! touch "${config_file}"
   then
      log_error "   | Failed to create configration file: ${config_file}"
      log_error "   ! Check your volume mount is not read-only. Check NFS/SMB share permissions if mounting to a shared location. Check you container has root permissions."
      log_error "   ! Cannot continue. Halting"
      sleep infinity
   fi
fi

# Check the config file isn't actually a directory
if [ ! -f "${config_file}" ]
then
   log_error "   | Config file appears to be a directory: ${config_file}"
   log_error "   ! Check your volume mount"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi

# Create enty config file, populate with default variables and configure it if Docker variables are also apecified
log_info " - Create/update configuration file: ${config_file}"
/usr/local/bin/init_config.sh

# Check config file was created and is writable
if [ ! -f "${config_file}" ]
then
   log_error "   | Failed to create configuration file: ${config_file}"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
elif [ ! -w "${config_file}" ]
then
   log_error "   | Cannot write to configuration file: ${config_file}"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi

# Load variables from config file
log_info " - Checking ${config_file} for errors"
source "${config_file}"

# Check Apple ID set
if [ -z "${apple_id}" ]
then
   log_error "   | Apple ID not set"
   log_error "   ! Waiting for it to be added to: ${config_file}"
   while [ -z "${apple_id}" ]
   do
      sleep 10
      source "${config_file}"
   done
fi

# Check user not attempting to configure the local user as root as this breaks the "runas" function
if [ "${group}" = "root" ]
then
   log_warning "   | The local group for synchronisation cannot be root, resetting to 'group'"
   sed -i "s%^group=$%group=group%" "${config_file}"
   user_warning_displayed=true
fi
if [ "${group_id}" -eq 0 ]
then
   log_warning "   | The local group id for synchronisation cannot be 0, resetting to '1000'"
   sed -i "s%^group_id=$%group_id=1000%" "${config_file}"
   user_warning_displayed=true
fi

# Check download path variable configured
if [ -z "${download_path}" ]
then
   log_error "   | Download path is not set properly in config"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi

# Initialise download path
if [ ! -d "${download_path}" ]
then
   log_info "   | Download directory does not exist"
   log_info "   | Creating ${download_path} and configuring permssions"
   
   if ! mkdir --parents "${download_path}"
   then 
      log_error "   | Failed to create download directory: '${download_path}'"
      log_error "   ! Cannot continue. Halting"
      sleep infinity
   fi
fi

# Initialise jpeg_path
if [ "${jpeg_path}" ] && [ ! -d "${jpeg_path}" ]
then
   log_info "   | JPEG directory does not exist"
   log_info "   | Creating ${jpeg_path}"
   
   if ! mkdir --parents "${jpeg_path}"
   then 
      log_error "   | Failed to create JPEG directory: '${jpeg_path}'"
      log_error "   ! Cannot continue. Halting"
      sleep infinity
   fi
fi

# Initialise videos_path
if [ "${video_path}" ] && [ ! -d "${video_path}" ]
then
   log_info "   | Video directory does not exist"
   log_info "   | Creating ${video_path}"
   
   if ! mkdir --parents "${video_path}"
   then 
      log_error "   | Failed to create video directory: '${video_path}'"
      log_error "   ! Cannot continue. Halting"
      sleep infinity
   fi
fi

# Warn if sync interval is too short
if [ "${synchronisation_interval}" -lt 43200 ] && [ "${warnings_acknowledged:=false}" = false ]
then
   log_warning "   | Setting synchronisation_interval to less than 43200 (12 hours) may cause throttling by Apple"
   log_warning "   ! If you run into the following error:"
   log_warning "   ! 'private db access disabled for this account. Please wait a few hours then try again. The remote servers might be trying to throttle requests. (ACCESS_DENIED)'"
   log_warning "   ! then check your synchronisation_interval is 43200 or greater and switch the container off for 6-12 hours so Apple's throttling expires"
   user_warning_displayed=true
fi

# Warn if set_exif_datetime is enabled
if [ "${set_exif_datetime}" = true ]
then
   log_warning "   | Configuring set_exif_datetime=true changes the files that are downloaded, so they will be downloaded a second time. Enabling this setting results in a lot of duplicate photos"
   user_warning_displayed=true
fi

# Halt on conflicting settings
if [ "${auto_delete}" != false ] && [ "${delete_after_download}" != false ]
then
   log_error "   | The variables auto_delete and delete_after_download cannot both be configured at the same time. Please choose one or the other. Halting"
   sleep infinity
fi
if [ "${sideways_copy_videos_mode}" = "move" ] && [ "${delete_after_download}" = false ]
then
   log_error "   | The variable sideways_copy_videos_mode cannot be set to 'move' unless delete_after_download is set to 'true', otherwise all icloud videos will be downloaded every run. Please set the copy mode to 'copy' or delete_after_download to 'true'. Halting"
   sleep infinity
fi

# Display warning when using keep_icloud_recent
if [ "${keep_icloud_recent_only}" = true ] && [ "${warnings_acknowledged:=false}" = false ]
then
   log_warning "   | The 'Keep iCloud recent' feature deletes all files from iCloud which are older than this amount of days. Setting this to 0 will delete everthing"
   log_warning "     Please use this with caution. I am not responsible for any data loss. Continuing in 2 minutes"
   user_warning_displayed=true
fi

# Display warning when deleting accompanying files
if [ "${delete_accompanying}" = true ] && [ "${warnings_acknowledged:=false}" = false ]
then
   log_info "   | Delete accompanying files (.JPG/.HEIC.MOV)"
   log_warning "   ! This feature deletes files from your local disk. Please use with caution. I am not responsible for any data loss"
   log_warning "   ! This feature cannot be used if the 'folder_structure' variable is set to 'none' and also, 'set_exif_datetime' must be 'false'"
   log_warning "   ! These two settings will increase the chances of de-duplication happening, which could result in the wrong files being removed"
   user_warning_displayed=true
fi

# Check China website and authentication sites are not mismatched
if [ "${icloud_china}" = true ]
then
   if [ "${auth_china}" != true ]
   then
       log_warning "   | You have the icloud_china variable set to true but auth_china set to false. Are you sure this is correct?"
       user_warning_displayed=true
   fi
fi

# Check all Nextcloud variables are present if Nextcloud uploading
if [ "${nextcloud_upload}" = true ]
then
   if [ -z "${nextcloud_url}" ] && [ -Z "${nextcloud_username}" ] && [ -z "${nextcloud_password}" ]
   then
       log_error "   | Nextcloud upload: Missing mandatory variables. Halting"
       sleep infinity
   fi
fi

# Skip delay when warnings are presented
if [ "${user_warning_displayed:=false}" = true ]
then
   if [ "${warnings_acknowledged:=false}" = true ]
   then
      log_debug "   | Configuration warnings acknowledged"
   else
      log_warning "Non-fatal configuration options detected. Continuing in 2 minutes..."
      sleep 120
   fi
fi

# Create group/user
log_info " - Checking user:group account: ${user}:${group}"
create_group
create_user

# Check/Set permissions
set_owner_and_permissions_config
set_owner_and_permissions_downloads
if [ "${jpeg_path}" ] && [ -d "${jpeg_path}" ]
then
   set_owner_and_permissions_jpegs
fi
if [ "${videos_path}" ] && [ -d "${videos_path}" ]
then
   set_owner_and_permissions_videos
fi

# Check config directory is writable by configured user
log_info " - Checking directories are writable by user: ${user}"
if [ "$(run_as "test -w /config/; echo $?")" -ne 0 ]
then
   log_error "   | Directory is not writable: /config/"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
# Check keyring directory is writable by configured user
if [ "$(run_as "test -w /config/python_keyring/; echo $?")" -ne 0 ]
then
   log_error "   | Directory is not writable: /config/python_keyring/"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi
# Check download directory is writable by configured user
if [ "$(run_as "test -w ${download_path}/; echo $?")" -ne 0 ]
then
   log_error "   | Directory is not writable: ${download_path}/"
   log_error "   ! Cannot continue. Halting"
   sleep infinity
fi

# Check JPEG directory is writable by configured user
if [ "${jpeg_path}" ] && [ ! -d "${jpeg_path}" ]
then
   log_info " - Testing JPEG directory writable by user: ${user}"
   if [ "$(run_as "test -w ${jpeg_path}/; echo $?")" -ne 0 ]
   then
      log_error "   | Directory is not writable: ${jpeg_path}/"
      log_error "   ! Cannot continue. Halting"
      sleep infinity
   fi
fi

# Check route to icloud web site
if [ "${icloud_china:=false}" = true ]
then
   icloud_domain="icloud.com.cn"
else
   icloud_domain="icloud.com"
fi
log_info " - Checking ${icloud_domain} is accessible"
if [ "$(traceroute -q 1 -w 1 ${icloud_domain} >/dev/null 2>/tmp/icloudpd/icloudpd_tracert.err; echo $?)" = 1 ]
then
   log_error "   | No route to ${icloud_domain} found. Please check your container's network settings"
   log_error "   ! Error debug - $(cat /tmp/icloudpd/icloudpd_tracert.err)"
   log_error "   ! Cannot continue. Restarting in 5 minutes"
   sleep 5m
   exit 1
fi

# Check Telegram bot initialised
if [ "${notification_type}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ] && [ "${telegram_polling}" = true ]
then
   log_info " - Checking Telegram bot initialised"
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
   telegram_update_id_offset_file="/config/telegram_update_id.num"
   if [ ! -f "${telegram_update_id_offset_file}" ]
   then
      echo -n 0 > "${telegram_update_id_offset_file}"
   fi
   sleep "$((RANDOM % 15))"
   bot_check="$(curl --silent -X POST "${telegram_base_url}/getUpdates" | jq -r .ok)"
   if [ "${bot_check}" = true ]
   then
      echo true > /tmp/icloudpd/bot_check
   else
      log_warning "   | Bot does not appear to have been initialised or needs reinitialising. Please send a message to the bot from your iDevice and restart the container"
      echo false > /tmp/icloudpd/bot_check
   fi
fi

# Check for updates
log_info_n " - Checking for updates: "
current_version="$(awk -F_ '{print $1}' /opt/build_version.txt)"
latest_version="$(curl --silent --max-time 5 https://raw.githubusercontent.com/boredazfcuk/docker-icloudpd/master/build_version.txt | awk -F_ '{print $1}')"
if [ "${current_version:=99}" -eq "99" ] || [ "${latest_version:=98}" -eq "98" ]
then
   echo "Check for updates failed. Placeholder version detected. Current version: ${current_version}. Latest version: ${latest_version}"
   user_warning_displayed=true
   sleep 1m
elif [ "${current_version}" -lt "${latest_version}" ]
then
   echo "Current version (v${current_version}) is out of date. Please upgrade to latest version (v${latest_version})."
   user_warning_displayed=true
   sleep 1m
elif [ "${current_version}" -gt "${latest_version}" ]
then
   echo "Current version (v${current_version}) is newer than latest build (v${latest_version}). Good luck!"
elif [ "${current_version}" -eq "${latest_version}" ]
then
   echo "Current version is up to date"
else
   echo "Check for updates failed. Cannot continue. Halting"
   sleep infinity
fi

log_info "Initialisation complete"
exec /usr/local/bin/sync-icloud.sh