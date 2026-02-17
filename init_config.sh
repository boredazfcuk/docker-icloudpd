#!/bin/ash

write_variable()
{
   variable="$1"
   default="$2"

   case " $found_variables " in
      *" $variable "*)
         return
         ;;
   esac

   # Get ENV override (ash-safe indirect expansion)
   eval env_value="\${$variable}"

   if [ -n "${env_value}" ]
   then
      value="${env_value}"
   elif [ -n "${default}" ]
   then
      value="${default}"
   else
      value=""
   fi

   printf '%s=%s\n' "${variable}" "${value}" >> "${temp_file}"
}

##### Start Script #####
config_file="/config/icloudpd.conf"

# Move from synchronisation_interval to download_interval and from synchronisation_delay to download_delay
if [ -f "${config_file}" ]
then
   sed -i 's/^synchronisation_interval=/download_interval=/g' "${config_file}"
   sed -i 's/^synchronisation_delay=/download_delay=/g' "${config_file}"
else
   touch "${config_file}"
fi

# Read config
config_content="$(cat "${config_file}")"

# Create temp file
temp_file="${config_file}.tmp"
true > "${temp_file}"

# Track which keys already exist
found_variables=""

# Copy file as-is and record existing variables
while IFS= read -r line || [ -n "$line" ]
do
   printf '%s\n' "$line" >> "${temp_file}"

   case "$line" in
      ''|\#*)
         # skip empty lines and comments
         continue
         ;;
      *=*)
         variable=${line%%=*}
         found_variables="$found_variables $variable"
         ;;
   esac
done < "${config_file}"

# Add variables to temporary config file
write_variable agentid
write_variable albums_with_dates false
write_variable align_raw as-is
write_variable apple_id
write_variable auth_china false
write_variable authentication_type MFA
write_variable auto_delete false
write_variable bark_device_key
write_variable bark_server
write_variable content_source_url
write_variable convert_heic_to_jpeg false
write_variable debug_logging false
write_variable delete_accompanying false
write_variable delete_after_download false
write_variable delete_empty_directories false
write_variable delete_notifications true
write_variable dingtalk_token
write_variable directory_permissions 750
write_variable discord_id
write_variable discord_token
write_variable download_delay 0
write_variable download_interval 86400
write_variable download_notifications true
write_variable download_path
write_variable fake_user_agent
write_variable file_match_policy name-size-dedup-with-suffix
write_variable file_permissions 640
write_variable folder_structure '{:%Y/%m/%d}'
write_variable force_gid false
write_variable gotify_app_token
write_variable gotify_https
write_variable gotify_server_url
write_variable group group
write_variable group_id 1000
write_variable icloud_china false
write_variable iyuu_token
write_variable jpeg_path
write_variable jpeg_quality 90
write_variable keep_icloud_recent_days
write_variable keep_icloud_recent_only
write_variable keep_unicode false
write_variable libraries_with_dates false
write_variable live_photo_mov_filename_policy suffix
write_variable live_photo_size original
write_variable media_id_delete
write_variable media_id_download
write_variable media_id_expiration
write_variable media_id_startup
write_variable media_id_warning
write_variable msmtp_args --tls-starttls=off
write_variable msmtp_auth on
write_variable msmtp_from
write_variable msmtp_host
write_variable msmtp_pass
write_variable msmtp_port
write_variable msmtp_tls on
write_variable msmtp_to
write_variable msmtp_user
write_variable name
write_variable nextcloud_delete false
write_variable nextcloud_password
write_variable nextcloud_upload false
write_variable nextcloud_url
write_variable nextcloud_username
write_variable notification_days 7
write_variable notification_type
write_variable photo_album
write_variable photo_library
write_variable photo_size original
write_variable prowl_api_key
write_variable pushover_sound
write_variable pushover_token
write_variable pushover_user
write_variable recent_only
write_variable set_exif_datetime false
write_variable sideways_copy_videos false
write_variable sideways_copy_videos_mode copy
write_variable signal_host
write_variable signal_number
write_variable signal_port
write_variable signal_recipient
write_variable silent_file_notifications false
write_variable single_pass false
write_variable skip_album
write_variable skip_check false
write_variable skip_created_after
write_variable skip_created_before
write_variable skip_download false
write_variable skip_library
write_variable skip_live_photos false
write_variable skip_videos false
write_variable startup_notification true
write_variable synology_ignore_path false
write_variable synology_photos_app_fix false
write_variable telegram_bot_initialised false
write_variable telegram_chat_id
write_variable telegram_http
write_variable telegram_polling true
write_variable telegram_server
write_variable telegram_token
write_variable touser
write_variable trigger_nextlcoudcli_download
write_variable until_found
write_variable user user
write_variable user_id 1000
write_variable video_path
write_variable webhook_https false
write_variable webhook_id
write_variable webhook_insecure
write_variable webhook_path /api/webhook/
write_variable webhook_port 8123
write_variable webhook_server
write_variable wecom_id
write_variable wecom_proxy
write_variable wecom_secret

# Set case sensitive variables to lowercase
notification_type_temp="$(grep -m1 "^notification_type=" "${temp_file}" | cut -d= -f2-)"
# Remove surrounding quotes
notification_type_temp="${notification_type_temp#\"}"
notification_type_temp="${notification_type_temp%\"}"
notification_type_lc="$(printf '%s' "${notification_type_temp}" | tr '[:upper:]' '[:lower:]')"
if [ -n "${notification_type_lc}" ]
then
   sed -i "s%^notification_type=.*%notification_type=${notification_type_lc}%" "${temp_file}"
fi

# Remove trailing slashes on directories
download_path_temp="$(grep -m1 "^download_path=" "${temp_file}" | cut -d= -f2-)"
download_path_temp="${download_path_temp#\"}"
download_path_temp="${download_path_temp%\"}"
download_path_temp="$(printf '%s' "${download_path_temp}")"
if [ -n "${download_path_temp}" ]
then
   sed -i "s#^download_path=.*#download_path=${download_path_temp%/}#" "${temp_file}"
fi

jpeg_path_temp="$(grep -m1 "^jpeg_path=" "${temp_file}" | cut -d= -f2-)"
jpeg_path_temp="${jpeg_path_temp#\"}"
jpeg_path_temp="${jpeg_path_temp%\"}"
jpeg_path_temp="$(printf '%s' "${jpeg_path_temp}")"
if [ -n "${jpeg_path_temp}" ]
then
   sed -i "s#^jpeg_path=.*#jpeg_path=${jpeg_path_temp%/}#" "${temp_file}"
fi

video_path_temp="$(grep -m1 "^video_path=" "${temp_file}" | cut -d= -f2-)"
video_path_temp="${video_path_temp#\"}"
video_path_temp="${video_path_temp%\"}"
video_path_temp="$(printf '%s' "${video_path_temp}")"
if [ -n "${video_path_temp}" ]
then
   sed -i "s%^video_path=.*%video_path=${video_path_temp%/}%" "${temp_file}"
fi

nextcloud_url_temp="$(grep -m1 "^nextcloud_url=" "${temp_file}" | cut -d= -f2-)"
nextcloud_url_temp="${nextcloud_url_temp#\"}"
nextcloud_url_temp="${nextcloud_url_temp%\"}"
nextcloud_url_temp="$(printf '%s' "${nextcloud_url_temp}")"
if [ -n "${nextcloud_url_temp}" ]
then
   sed -i "s%^nextcloud_url=.*%nextcloud_url=${nextcloud_url_temp%/}%" "${temp_file}"
fi

nextcloud_target_dir_temp="$(grep -m1 "^nextcloud_target_dir=" "${temp_file}" | cut -d= -f2-)"
nextcloud_target_dir_temp="${nextcloud_target_dir_temp#\"}"
nextcloud_target_dir_temp="${nextcloud_target_dir_temp%\"}"
nextcloud_target_dir_temp="$(printf '%s' "${nextcloud_target_dir_temp}")"
if [ -n "${nextcloud_target_dir_temp}" ]
then
   sed -i "s%^nextcloud_target_dir=.*%nextcloud_target_dir=${nextcloud_target_dir_temp%/}%" "${temp_file}"
fi

# Normalise boolean
sed -i 's/=True/=true/gI' "${temp_file}"
sed -i 's/=False/=false/gI' "${temp_file}"

# Update config file
chowner="$(grep -m1 "^user_id=" "${temp_file}" | cut -d= -f2-)"
chgrper="$(grep -m1 "^group_id=" "${temp_file}" | cut -d= -f2-)"
chown "${chowner}":"${chgrper}" "${temp_file}"
mv  "${temp_file}" "${config_file}"