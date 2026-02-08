#!/bin/ash

# Move from synchronisation_interval to download_interval and from synchronisation_delay to download_delay
if [ -f "${config_file}" ]
then
   sed -i 's/^synchronisation_interval=/download_interval=/g' "${config_file}"
   sed -i 's/^synchronisation_delay=/download_delay=/g' "${config_file}"
fi

vars="agentid
albums_with_dates
align_raw
apple_id
auth_china
authentication_type
auto_delete
bark_device_key
bark_server
content_source_url
convert_heic_to_jpeg
debug_logging
delete_accompanying
delete_after_download
delete_empty_directories
delete_notifications
dingtalk_token
directory_permissions
discord_id
discord_token
download_delay
download_interval
download_notifications
download_path
fake_user_agent
file_match_policy
file_permissions
folder_structure
force_gid
gotify_app_token
gotify_https
gotify_server_url
group
group_id
icloud_china
iyuu_token
jpeg_path
jpeg_quality
keep_icloud_recent_days
keep_icloud_recent_only
keep_unicode
libraries_with_dates
live_photo_mov_filename_policy
live_photo_size
media_id_delete
media_id_download
media_id_expiration
media_id_startup
media_id_warning
msmtp_args
msmtp_auth
msmtp_from
msmtp_host
msmtp_pass
msmtp_port
msmtp_tls
msmtp_to
msmtp_user
name
nextcloud_delete
nextcloud_password
nextcloud_upload
nextcloud_url
nextcloud_username
notification_days
notification_type
photo_album
photo_library
photo_size
prowl_api_key
pushover_sound
pushover_token
pushover_user
recent_only
set_exif_datetime
sideways_copy_videos
sideways_copy_videos_mode
signal_host
signal_number
signal_port
signal_recipient
silent_file_notifications
single_pass
skip_album
skip_check
skip_created_after
skip_created_before
skip_download
skip_library
skip_live_photos
skip_videos
startup_notification
synology_ignore_path
synology_photos_app_fix
telegram_bot_initialised
telegram_chat_id
telegram_http
telegram_polling
telegram_server
telegram_token
touser
trigger_nextlcoudcli_download
until_found
user
user_id
video_path
webhook_https
webhook_id
webhook_insecure
webhook_path
webhook_port
webhook_server
wecom_id
wecom_proxy"

# Loop over each variable
for var in $vars
do
   # Check if variable is already in the config file
   if ! grep -q "^${var}=" "$config_file"
   then
      # Use default value if variable is unset
      case $var in
         albums_with_dates) default_val="false" ;;
         align_raw) default_val="as-is" ;;
         apple_id) default_val="" ;;
         auth_china) default_val="false" ;;
         authentication_type) default_val="MFA" ;;
         auto_delete) default_val="false" ;;
         convert_heic_to_jpeg) default_val="false" ;;
         debug_logging) default_val="false" ;;
         delete_accompanying) default_val="false" ;;
         delete_after_download) default_val="false" ;;
         delete_empty_directories) default_val="false" ;;
         delete_notifications) default_val="true" ;;
         directory_permissions) default_val="750" ;;
         download_delay) default_val="0" ;;
         download_interval) default_val="86400" ;;
         download_notifications) default_val="true" ;;
         download_path)
            if [ -s "${config_file}" ]
            then
               user="$(grep "^user=" "${config_file}" | cut -d= -f2- | tr -d '[:space:]')"
            fi
            default_val="${download_path:-/home/${user:-user}/iCloud}"
            ;;
         file_match_policy) default_val="name-size-dedup-with-suffix" ;;
         file_permissions) default_val="640" ;;
         folder_structure) default_val="{:%Y/%m/%d\}" ;;
         force_gid) default_val="false" ;;
         group) default_val="group" ;;
         group_id)  default_val="1000" ;;
         icloud_china) default_val="false" ;;
         jpeg_quality) default_val="90" ;;
         keep_unicode) default_val="false" ;;
         libraries_with_dates) default_val="false" ;;
         live_photo_mov_filename_policy) default_val="suffix" ;;
         live_photo_size) default_val="original" ;;
         msmtp_args) default_val="--tls-starttls=off" ;;
         msmtp_auth) default_val="on" ;;
         msmtp_tls) default_val="on" ;;
         nextcloud_delete) default_val="false" ;;
         nextcloud_upload) default_val="false" ;;
         notification_days) default_val="7" ;;
         photo_size) default_val="original" ;;
         set_exif_datetime) default_val="false" ;;
         sideways_copy_videos) default_val="false" ;;
         sideways_copy_videos_mode) default_val="copy" ;;
         silent_file_notifications) default_val="false" ;;
         single_pass) default_val="false" ;;
         skip_check) default_val="false" ;;
         skip_download) default_val="false" ;;
         skip_live_photos) default_val="false" ;;
         skip_videos) default_val="false" ;;
         startup_notification) default_val="true" ;;
         synology_ignore_path) default_val="false" ;;
         synology_photos_app_fix) default_val="false" ;;
         telegram_bot_initialised) default_val="false" ;;
         telegram_polling) default_val="true" ;;
         user) default_val="user" ;;
         user_id) default_val="1000" ;;
         webhook_https) default_val="false" ;;
         webhook_path) default_val="/api/webhook/" ;;
         webhook_port) default_val="8123" ;;
         *) default_val="" ;;
      esac

      # Write to the config file
      env_val="$(printenv "$var")"

      if [ -n "$env_val" ]; then
         value="$env_val"
      else
         value="$default_val"
      fi

      echo "${var}=\"${value}\"" >> "${config_file}"
   fi
done

# Set case sensitive variables to lowercase
notification_type_lc="$(grep "^notification_type=" "${config_file}" | cut -d= -f2- | tr '[:upper:]' '[:lower:]')"
if [ "${notification_type_lc}" ]
then
   sed -i "s#^notification_type=.*#notification_type=${notification_type_lc}#" "${config_file}"
fi
# Remove trailing slashes on directories
download_path_temp="$(grep "^download_path=" "${config_file}" | cut -d= -f2- | sed 's/^"//; s/"$//')"
if [ "${download_path_temp}" ]
then
   sed -i "s#^download_path=.*#download_path=\"${download_path_temp%%/}\"#" "${config_file}"
fi
jpeg_path_temp="$(grep "^jpeg_path=" "${config_file}" | cut -d= -f2- | sed 's/^"//; s/"$//')"
if [ "${jpeg_path_temp}" ]
then
   sed -i "s#^jpeg_path=.*#jpeg_path=\"${jpeg_path_temp%%/}\"#" "${config_file}"
fi
video_path_temp="$(grep "^video_path=" "${config_file}" | cut -d= -f2- | sed 's/^"//; s/"$//')"
if [ "${video_path_temp}" ]
then
   sed -i "s#^video_path=.*#video_path=\"${video_path_temp%%/}\"#" "${config_file}"
fi
nextcloud_url_temp="$(grep "^nextcloud_url=" "${config_file}" | cut -d= -f2-)"
if [ "${nextcloud_url_temp}" ]
then
   sed -i "s#^nextcloud_url=.*#nextcloud_url=${nextcloud_url_temp%%/}#" "${config_file}"
fi
nextcloud_target_dir_temp="$(grep "^nextcloud_target_dir=" "${config_file}" | cut -d= -f2-)"
if [ "${nextcloud_target_dir_temp}" ]
then
   sed -i "s#^nextcloud_target_dir=.*#nextcloud_target_dir=${nextcloud_target_dir_temp%%/}#" "${config_file}"
fi

# Update config file
sort "${config_file}" -o "${config_file}.tmp"
sed -i '/^$/d' "${config_file}.tmp"
chmod --reference="${config_file}" "${config_file}.tmp"
mv "${config_file}.tmp" "${config_file}"

sed -i -e 's/=True/=true/gI' -e 's/=False/=false/gI' "$config_file"
sed -i 's/authentication_type=2FA/authentication_type=MFA/' "${config_file}"