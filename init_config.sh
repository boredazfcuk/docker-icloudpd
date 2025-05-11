#!/bin/ash

# Move from synchronisation_interval to download_interval and from synchronisation_delay to download_delay
if [ -f "${config_file}" ]
then
   sed -i 's/^synchronisation_interval=/download_interval=/g' "${config_file}"
   sed -i 's/^synchronisation_delay=/download_delay=/g' "${config_file}"
fi

# Add missing options to the config file and if a Docker variable exists, use that to set the default value
{
   if [ "$(grep -c "^albums_with_dates=" "${config_file}")" -eq 0 ]
   then
      echo albums_with_dates="${albums_with_dates:=false}"
   fi
   if [ "$(grep -c "^align_raw=" "${config_file}")" -eq 0 ]
   then
      echo align_raw="${align_raw:=as-is}"
   fi
   if [ "$(grep -c "^apple_id=" "${config_file}")" -eq 0 ]
   then
      echo apple_id="${apple_id}"
   fi
   if [ "$(grep -c "^authentication_type=" "${config_file}")" -eq 0 ]
   then
      echo authentication_type="${authentication_type:=MFA}"
   fi
   if [ "$(grep -c "^auth_china=" "${config_file}")" -eq 0 ]
   then
      echo auth_china="${auth_china:=false}"
   fi
   if [ "$(grep -c "^auto_delete=" "${config_file}")" -eq 0 ]
   then
      echo auto_delete="${auto_delete:=false}"
   fi
   if [ "$(grep -c "^bark_device_key=" "${config_file}")" -eq 0 ]
   then
      echo bark_device_key="${bark_device_key}"
   fi
   if [ "$(grep -c "^bark_server=" "${config_file}")" -eq 0 ]
   then
      echo bark_server="${bark_server}"
   fi
   if [ "$(grep -c "^convert_heic_to_jpeg=" "${config_file}")" -eq 0 ]
   then
      echo convert_heic_to_jpeg="${convert_heic_to_jpeg:=false}"
   fi
   if [ "$(grep -c "^debug_logging=" "${config_file}")" -eq 0 ]
   then
      echo debug_logging="${debug_logging:=false}"
   fi
   if [ "$(grep -c "^delete_accompanying=" "${config_file}")" -eq 0 ]
   then
      echo delete_accompanying="${delete_accompanying:=false}"
   fi
   if [ "$(grep -c "^delete_after_download=" "${config_file}")" -eq 0 ]
   then
      echo delete_after_download="${delete_after_download:=false}"
   fi
   if [ "$(grep -c "^delete_empty_directories=" "${config_file}")" -eq 0 ]
   then
      echo delete_empty_directories="${delete_empty_directories:=false}"
   fi
   if [ "$(grep -c "^delete_notifications=" "${config_file}")" -eq 0 ]
   then
      echo delete_notifications="${delete_notifications:=true}"
   fi
   if [ "$(grep -c "^dingtalk_token=" "${config_file}")" -eq 0 ]
   then
      echo dingtalk_token="${dingtalk_token}"
   fi
   if [ "$(grep -c "^directory_permissions=" "${config_file}")" -eq 0 ]
   then
      echo directory_permissions="${directory_permissions:=750}"
   fi
   if [ "$(grep -c "^discord_id=" "${config_file}")" -eq 0 ]
   then
      echo discord_id="${discord_id}"
   fi
   if [ "$(grep -c "^discord_token=" "${config_file}")" -eq 0 ]
   then
      echo discord_token="${discord_token}"
   fi
   if [ "$(grep -c "^download_notifications=" "${config_file}")" -eq 0 ]
   then
      echo download_notifications="${download_notifications:=true}"
   fi
   if [ "$(grep -c "^download_path=" "${config_file}")" -eq 0 ]
   then
      user="$(grep "^user=" "${config_file}" | awk -F= '{print $2}')"
      echo download_path="${download_path:=/home/${user:=user}/iCloud}"
   fi
   if [ "$(grep -c "^fake_user_agent=" "${config_file}")" -eq 0 ]
   then
      echo fake_user_agent="${fake_user_agent}"
   fi
   if [ "$(grep -c "^file_match_policy=" "${config_file}")" -eq 0 ]
   then
      echo file_match_policy="${file_match_policy:=name-size-dedup-with-suffix}"
   fi
   if [ "$(grep -c "^file_permissions=" "${config_file}")" -eq 0 ]
   then
      echo file_permissions="${file_permissions:=640}"
   fi
   if [ "$(grep -c "^folder_structure=" "${config_file}")" -eq 0 ]
   then
      echo folder_structure="${folder_structure:={:%Y/%m/%d\}}"
   fi
   if [ "$(grep -c "^force_gid=" "${config_file}")" -eq 0 ]
   then
      echo force_gid="${force_gid:=false}"
   fi
   if [ "$(grep -c "^gotify_app_token=" "${config_file}")" -eq 0 ]
   then
      echo gotify_app_token="${gotify_app_token}"
   fi
   if [ "$(grep -c "^gotify_https=" "${config_file}")" -eq 0 ]
   then
      echo gotify_https="${gotify_https}"
   fi
   if [ "$(grep -c "^gotify_server_url=" "${config_file}")" -eq 0 ]
   then
      echo gotify_server_url="${gotify_server_url}"
   fi
   if [ "$(grep -c "^group=" "${config_file}")" -eq 0 ]
   then
      echo group="${group:=group}"
   fi
   if [ "$(grep -c "^group_id=" "${config_file}")" -eq 0 ]
   then
      echo group_id="${group_id:=1000}"
   fi
   if [ "$(grep -c "^icloud_china=" "${config_file}")" -eq 0 ]
   then
      echo icloud_china="${icloud_china:=false}"
   fi
   if [ "$(grep -c "^iyuu_token=" "${config_file}")" -eq 0 ]
   then
      echo iyuu_token="${iyuu_token}"
   fi
   if [ "$(grep -c "^jpeg_path=" "${config_file}")" -eq 0 ]
   then
      echo jpeg_path="${jpeg_path}"
   fi
   if [ "$(grep -c "^jpeg_quality=" "${config_file}")" -eq 0 ]
   then
      echo jpeg_quality="${jpeg_quality:=90}"
   fi
   if [ "$(grep -c "^keep_icloud_recent_days=" "${config_file}")" -eq 0 ]
   then
      echo keep_icloud_recent_days="${keep_icloud_recent_days}"
   fi
   if [ "$(grep -c "^keep_icloud_recent_only=" "${config_file}")" -eq 0 ]
   then
      echo keep_icloud_recent_only="${keep_icloud_recent_only}"
   fi
   if [ "$(grep -c "^keep_unicode=" "${config_file}")" -eq 0 ]
   then
      echo keep_unicode="${keep_unicode:=false}"
   fi
   if [ "$(grep -c "^libraries_with_dates=" "${config_file}")" -eq 0 ]
   then
      echo libraries_with_dates="${libraries_with_dates:=false}"
   fi
   if [ "$(grep -c "^live_photo_mov_filename_policy=" "${config_file}")" -eq 0 ]
   then
      echo live_photo_mov_filename_policy="${live_photo_mov_filename_policy:=suffix}"
   fi
   if [ "$(grep -c "^live_photo_size=" "${config_file}")" -eq 0 ]
   then
      echo live_photo_size="${live_photo_size:=original}"
   fi
   if [ "$(grep -c "^nextcloud_delete=" "${config_file}")" -eq 0 ]
   then
      echo nextcloud_delete="${nextcloud_delete:=false}"
   fi
   if [ "$(grep -c "^nextcloud_upload=" "${config_file}")" -eq 0 ]
   then
      echo nextcloud_upload="${nextcloud_upload:=false}"
   fi
   if [ "$(grep -c "^nextcloud_url=" "${config_file}")" -eq 0 ]
   then
      echo nextcloud_url="${nextcloud_url}"
   fi
   if [ "$(grep -c "^nextcloud_username=" "${config_file}")" -eq 0 ]
   then
      echo nextcloud_username="${nextcloud_username}"
   fi
   if [ "$(grep -c "^nextcloud_password=" "${config_file}")" -eq 0 ]
   then
      echo nextcloud_password="${nextcloud_password}"
   fi
   if [ "$(grep -c "^notification_days=" "${config_file}")" -eq 0 ]
   then
      echo notification_days="${notification_days:=7}"
   fi
   if [ "$(grep -c "^notification_type=" "${config_file}")" -eq 0 ]
   then
      echo notification_type="${notification_type}"
   fi
   if [ "$(grep -c "^photo_album=" "${config_file}")" -eq 0 ]
   then
      echo photo_album="${photo_album}"
   fi
   if [ "$(grep -c "^photo_library=" "${config_file}")" -eq 0 ]
   then
      echo photo_library="${photo_library}"
   fi
   if [ "$(grep -c "^photo_size=" "${config_file}")" -eq 0 ]
   then
      echo photo_size="${photo_size:=original}"
   fi
   if [ "$(grep -c "^prowl_api_key=" "${config_file}")" -eq 0 ]
   then
      echo prowl_api_key="${prowl_api_key}"
   fi
   if [ "$(grep -c "^pushover_sound=" "${config_file}")" -eq 0 ]
   then
      echo pushover_sound="${pushover_sound}"
   fi
   if [ "$(grep -c "^pushover_token=" "${config_file}")" -eq 0 ]
   then
      echo pushover_token="${pushover_token}"
   fi
   if [ "$(grep -c "^pushover_user=" "${config_file}")" -eq 0 ]
   then
      echo pushover_user="${pushover_user}"
   fi
   if [ "$(grep -c "^recent_only=" "${config_file}")" -eq 0 ]
   then
      echo recent_only="${recent_only}"
   fi
   if [ "$(grep -c "^set_exif_datetime=" "${config_file}")" -eq 0 ]
   then
      echo set_exif_datetime="${set_exif_datetime:=false}"
   fi
   if [ "$(grep -c "^sideways_copy_videos=" "${config_file}")" -eq 0 ]
   then
      echo sideways_copy_videos="${sideways_copy:=false}"
   fi
   if [ "$(grep -c "^sideways_copy_videos_mode=" "${config_file}")" -eq 0 ]
   then
      echo sideways_copy_videos_mode="${sideways_copy_mode:=copy}"
   fi
   if [ "$(grep -c "^signal_host=" "${config_file}")" -eq 0 ]
   then
      echo signal_host="${signal_host}"
   fi
   if [ "$(grep -c "^signal_port=" "${config_file}")" -eq 0 ]
   then
      echo signal_port="${signal_port}"
   fi
   if [ "$(grep -c "^signal_number=" "${config_file}")" -eq 0 ]
   then
      echo signal_number="${signal_number}"
   fi
   if [ "$(grep -c "^signal_recipient=" "${config_file}")" -eq 0 ]
   then
      echo signal_recipient="${signal_recipient}"
   fi
   if [ "$(grep -c "^silent_file_notifications=" "${config_file}")" -eq 0 ]
   then
      echo silent_file_notifications="${silent_file_notifications:=false}"
   fi
   if [ "$(grep -c "^single_pass=" "${config_file}")" -eq 0 ]
   then
      echo single_pass="${single_pass:=false}"
   fi
   if [ "$(grep -c "^skip_album=" "${config_file}")" -eq 0 ]
   then
      echo skip_album="${skip_album}"
   fi
   if [ "$(grep -c "^skip_library=" "${config_file}")" -eq 0 ]
   then
      echo skip_library="${skip_library}"
   fi
   if [ "$(grep -c "^skip_check=" "${config_file}")" -eq 0 ]
   then
      echo skip_check="${skip_check:=false}"
   fi
   if [ "$(grep -c "^skip_download=" "${config_file}")" -eq 0 ]
   then
      echo skip_download="${skip_download:=false}"
   fi
   if [ "$(grep -c "^skip_live_photos=" "${config_file}")" -eq 0 ]
   then
      echo skip_live_photos="${skip_live_photos:=false}"
   fi
   if [ "$(grep -c "^skip_videos=" "${config_file}")" -eq 0 ]
   then
      echo skip_videos="${skip_videos:=false}"
   fi
   if [ "$(grep -c "^startup_notification=" "${config_file}")" -eq 0 ]
   then
      echo startup_notification="${startup_notification:=true}"
   fi
   if [ "$(grep -c "^download_delay=" "${config_file}")" -eq 0 ]
   then
      echo download_delay="${download_delay:=0}"
   fi
   if [ "$(grep -c "^download_interval=" "${config_file}")" -eq 0 ]
   then
      echo download_interval="${download_interval:=86400}"
   fi
   if [ "$(grep -c "^synology_ignore_path=" "${config_file}")" -eq 0 ]
   then
      echo synology_ignore_path="${synology_ignore_path:=false}"
   fi
   if [ "$(grep -c "^synology_photos_app_fix=" "${config_file}")" -eq 0 ]
   then
      echo synology_photos_app_fix="${synology_photos_app_fix:=false}"
   fi
   if [ "$(grep -c "^telegram_bot_initialised=" "${config_file}")" -eq 0 ]
   then
      echo telegram_bot_initialised=false
   fi
   if [ "$(grep -c "^telegram_chat_id=" "${config_file}")" -eq 0 ]
   then
      echo telegram_chat_id="${telegram_chat_id}"
   fi
   if [ "$(grep -c "^telegram_http=" "${config_file}")" -eq 0 ]
   then
      echo telegram_http="${telegram_http}"
   fi
   if [ "$(grep -c "^telegram_polling=" "${config_file}")" -eq 0 ]
   then
      echo telegram_polling="${telegram_polling:=true}"
   fi
   if [ "$(grep -c "^telegram_server=" "${config_file}")" -eq 0 ]
   then
      echo telegram_server="${telegram_server}"
   fi
   if [ "$(grep -c "^telegram_token=" "${config_file}")" -eq 0 ]
   then
      echo telegram_token="${telegram_token}"
   fi
   if [ "$(grep -c "^trigger_nextlcoudcli_download=" "${config_file}")" -eq 0 ]
   then
      echo trigger_nextlcoudcli_download="${trigger_nextlcoudcli_download}"
   fi
   if [ "$(grep -c "^until_found=" "${config_file}")" -eq 0 ]
   then
      echo until_found="${until_found}"
   fi
   if [ "$(grep -c "^user=" "${config_file}")" -eq 0 ]
   then
      echo user="${user:=user}"
   fi
   if [ "$(grep -c "^user_id=" "${config_file}")" -eq 0 ]
   then
      echo user_id="${user_id:=1000}"
   fi
   if [ "$(grep -c "^video_path=" "${config_file}")" -eq 0 ]
   then
      echo video_path=
   fi
   if [ "$(grep -c "^webhook_https=" "${config_file}")" -eq 0 ]
   then
      echo webhook_https="${webhook_https:=false}"
   fi
   if [ "$(grep -c "^webhook_id=" "${config_file}")" -eq 0 ]
   then
      echo webhook_id="${webhook_id}"
   fi
   if [ "$(grep -c "^webhook_path=" "${config_file}")" -eq 0 ]
   then
      echo webhook_path="${webhook_path:=/api/webhook/}"
   fi
   if [ "$(grep -c "^webhook_port=" "${config_file}")" -eq 0 ]
   then
      echo webhook_port="${webhook_port:=8123}"
   fi
   if [ "$(grep -c "^webhook_server=" "${config_file}")" -eq 0 ]
   then
      echo webhook_server="${webhook_server}"
   fi
   if [ "$(grep -c "^webhook_insecure=" "${config_file}")" -eq 0 ]
   then
      echo webhook_insecure="${webhook_insecure}"
   fi
   if [ "$(grep -c "^wecom_id=" "${config_file}")" -eq 0 ]
   then
      echo wecom_id="${wecom_id}"
   fi
   if [ "$(grep -c "^wecom_proxy=" "${config_file}")" -eq 0 ]
   then
      echo wecom_proxy="${wecom_proxy}"
   fi
   if [ "$(grep -c "^wecom_secret=" "${config_file}")" -eq 0 ]
   then
      echo wecom_secret="${wecom_secret}"
   fi
   if [ "$(grep -c "^msmtp_host=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_host="${msmtp_host}"
   fi
   if [ "$(grep -c "^msmtp_port=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_port="${msmtp_port}"
   fi
   if [ "$(grep -c "^msmtp_user=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_user="${msmtp_user}"
   fi
   if [ "$(grep -c "^msmtp_from=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_from="${msmtp_from}"
   fi
   if [ "$(grep -c "^msmtp_pass=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_pass="${msmtp_pass}"
   fi
   if [ "$(grep -c "^msmtp_tls=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_tls="${msmtp_tls:=on}"
   fi
   if [ "$(grep -c "^msmtp_to=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_to="${msmtp_to}"
   fi
   if [ "$(grep -c "^msmtp_args=" "${config_file}")" -eq 0 ]
   then
      echo msmtp_args="${msmtp_args:=--tls-starttls=off}"
   fi
   if [ "$(grep -c "^agentid=" "${config_file}")" -eq 0 ]
   then
      echo agentid="${agentid}"
   fi
   if [ "$(grep -c "^touser=" "${config_file}")" -eq 0 ]
   then
      echo touser="${touser}"
   fi
   if [ "$(grep -c "^content_source_url=" "${config_file}")" -eq 0 ]
   then
      echo content_source_url="${content_source_url}"
   fi
   if [ "$(grep -c "^name=" "${config_file}")" -eq 0 ]
   then
      echo name="${name}"
   fi
   if [ "$(grep -c "^media_id_startup=" "${config_file}")" -eq 0 ]
   then
      echo media_id_startup="${media_id_startup}"
   fi
   if [ "$(grep -c "^media_id_download=" "${config_file}")" -eq 0 ]
   then
      echo media_id_download="${media_id_download}"
   fi
   if [ "$(grep -c "^media_id_delete=" "${config_file}")" -eq 0 ]
   then
      echo media_id_delete="${media_id_delete}"
   fi
   if [ "$(grep -c "^media_id_expiration=" "${config_file}")" -eq 0 ]
   then
      echo media_id_expiration="${media_id_expiration}"
   fi
   if [ "$(grep -c "^media_id_warning=" "${config_file}")" -eq 0 ]
   then
      echo media_id_warning="${media_id_warning}"
   fi
} > "${config_file}.add"
if [ -f "${config_file}.add" ]
then
   cat "${config_file}.add" >> "${config_file}"
   rm "${config_file}.add"
fi

# Set default values if missing from config file
if [ -z "$(grep "^authentication_type=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^authentication_type=$%authentication_type=MFA%" "${config_file}"
fi
if [ -z "$(grep "^auth_china=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^auth_china=$%auth_china=false%" "${config_file}"
fi
if [ -z "$(grep "^auto_delete=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^auto_delete=$%auto_delete=false%" "${config_file}"
fi
if [ -z "$(grep "^albums_with_dates=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^albums_with_dates=$%albums_with_dates=false%" "${config_file}"
fi
if [ -z "$(grep "^align_raw=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^align_raw=$%align_raw=as-is%" "${config_file}"
fi
if [ -z "$(grep "^convert_heic_to_jpeg=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^convert_heic_to_jpeg=$%convert_heic_to_jpeg=false%" "${config_file}"
fi
if [ -z "$(grep "^debug_logging=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^debug_logging=$%debug_logging=false%" "${config_file}"
fi
if [ -z "$(grep "^delete_accompanying=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^delete_accompanying=$%delete_accompanying=false%" "${config_file}"
fi
if [ -z "$(grep "^delete_after_download=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^delete_after_download=$%delete_after_download=false%" "${config_file}"
fi
if [ -z "$(grep "^delete_empty_directories=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^delete_empty_directories=$%delete_empty_directories=false%" "${config_file}"
fi
if [ -z "$(grep "^delete_notifications=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^delete_notifications=$%delete_notifications=true%" "${config_file}"
fi
if [ -z "$(grep "^directory_permissions=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^directory_permissions=$%directory_permissions=750%" "${config_file}"
fi
if [ -z "$(grep "^download_notifications=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^download_notifications=$%download_notifications=true%" "${config_file}"
fi
if [ -z "$(grep "^download_path=" "${config_file}" | awk -F= '{print $2}')" ]
then
   user="$(grep "^user=" "${config_file}" | awk -F= '{print $2}')"
   sed -i "s%^download_path=$%download_path=${download_path:=/home/${user:=user}/iCloud}%" "${config_file}"
fi
if [ -z "$(grep "^fake_user_agent=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^fake_user_agent=$%fake_user_agent=false%" "${config_file}"
fi
if [ -z "$(grep "^file_match_policy=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^file_match_policy=$%file_match_policy=name-size-dedup-with-suffix%" "${config_file}"
fi
if [ -z "$(grep "^file_permissions=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^file_permissions=$%file_permissions=640%" "${config_file}"
fi
if [ -z "$(grep "^folder_structure=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^folder_structure=$%folder_structure={:\%Y/\%m/\%d\}%" "${config_file}"
fi
if [ -z "$(grep "^force_gid=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^force_gid=$%force_gid=false%" "${config_file}"
fi
if [ -z "$(grep "^group=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^group=$%group=group%" "${config_file}"
fi
if [ -z "$(grep "^group_id=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^group_id=$%group_id=1000%" "${config_file}"
fi
if [ -z "$(grep "^icloud_china=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^icloud_china=$%icloud_china=false%" "${config_file}"
fi
if [ -z "$(grep "^jpeg_quality=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^jpeg_quality=$%jpeg_quality=90%" "${config_file}"
fi
if [ -z "$(grep "^keep_icloud_recent_only=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^keep_icloud_recent_only=$%keep_icloud_recent_only=false%" "${config_file}"
fi
if [ -z "$(grep "^keep_unicode=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^keep_unicode=$%keep_unicode=false%" "${config_file}"
fi
if [ -z "$(grep "^libraries_with_dates=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^libraries_with_dates=$%libraries_with_dates=false%" "${config_file}"
fi
if [ -z "$(grep "^live_photo_mov_filename_policy=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^live_photo_mov_filename_policy=$%live_photo_mov_filename_policy=suffix%" "${config_file}"
fi
if [ -z "$(grep "^live_photo_size=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^live_photo_size=$%live_photo_size=original%" "${config_file}"
fi
if [ -z "$(grep "^nextcloud_delete=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^nextcloud_delete=$%nextcloud_delete=false%" "${config_file}"
fi
if [ -z "$(grep "^nextcloud_upload=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^nextcloud_upload=$%nextcloud_upload=false%" "${config_file}"
fi
if [ -z "$(grep "^notification_days=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^notification_days=$%notification_days=7%" "${config_file}"
fi
if [ -z "$(grep "^photo_size=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^photo_size=$%photo_size=original%" "${config_file}"
fi
if [ -z "$(grep "^set_exif_datetime=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^set_exif_datetime=$%set_exif_datetime=false%" "${config_file}"
fi
if [ -z "$(grep "^sideways_copy_videos=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^sideways_copy_videos=$%sideways_copy_videos=false%" "${config_file}"
fi
if [ -z "$(grep "^sideways_copy_videos_mode=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^sideways_copy_videos_mode=$%sideways_copy_videos_mode=copy%" "${config_file}"
fi
if [ -z "$(grep "^single_pass=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^single_pass=$%single_pass=false%" "${config_file}"
fi
if [ -z "$(grep "^skip_check=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^skip_check=$%skip_check=false%" "${config_file}"
fi
if [ -z "$(grep "^skip_download=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^skip_download=$%skip_download=false%" "${config_file}"
fi
if [ -z "$(grep "^skip_live_photos=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^skip_live_photos=$%skip_live_photos=false%" "${config_file}"
fi
if [ -z "$(grep "^skip_videos=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^skip_videos=$%skip_videos=false%" "${config_file}"
fi
if [ -z "$(grep "^startup_notification=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^startup_notification=$%startup_notification=true%" "${config_file}"
fi
if [ -z "$(grep "^download_delay=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^download_delay=$%download_delay=0%" "${config_file}"
fi
if [ -z "$(grep "^download_interval=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^download_interval=$%download_interval=86400%" "${config_file}"
fi
if [ -z "$(grep "^synology_ignore_path=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^synology_ignore_path=$%synology_ignore_path=false%" "${config_file}"
fi
if [ -z "$(grep "^synology_photos_app_fix=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^synology_photos_app_fix=$%synology_photos_app_fix=false%" "${config_file}"
fi
if [ -z "$(grep "^telegram_http=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^telegram_http=$%telegram_http=false%" "${config_file}"
fi
if [ -z "$(grep "^user=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^user=$%user=user%" "${config_file}"
fi
if [ -z "$(grep "^user_id=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^user_id=$%user_id=1000%" "${config_file}"
fi
if [ -z "$(grep "^webhook_https=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^webhook_https=$%webhook_https=false%" "${config_file}"
fi
if [ -z "$(grep "^webhook_path=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^webhook_path=$%webhook_path=/api/webhook/%" "${config_file}"
fi
if [ -z "$(grep "^webhook_port=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^webhook_port=$%webhook_port=8123%" "${config_file}"
fi
if [ -z "$(grep "^webhook_insecure=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^webhook_insecure=$%webhook_insecure=false%" "${config_file}"
fi
if [ -z "$(grep "^msmtp_tls=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^msmtp_tls=$%msmtp_tls=on%" "${config_file}"
fi
if [ -z "$(grep "^msmtp_args=" "${config_file}" | awk -F= '{print $2}')" ]
then
   sed -i "s%^msmtp_args=$%msmtp_args=--tls-starttls=off%" "${config_file}"
fi

# Update configuration file with with values from Docker environment variables, in case they've changed
if [ "${albums_with_dates}" ]
then
   sed -i "s%^albums_with_dates=.*%albums_with_dates=${albums_with_dates}%" "${config_file}"
fi
if [ "${align_raw}" ]
then
   sed -i "s%^align_raw=.*%align_raw=${align_raw}%" "${config_file}"
fi
if [ "${apple_id}" ]
then
   sed -i "s%^apple_id=.*%apple_id=${apple_id}%" "${config_file}"
fi
if [ "${authentication_type}" ]
then
   sed -i "s%^authentication_type=.*%authentication_type=${authentication_type}%" "${config_file}"
fi
if [ "${auth_china}" ]
then
   sed -i "s%^auth_china=.*%auth_china=${auth_china}%" "${config_file}"
fi
if [ "${auto_delete}" ]
then
   sed -i "s%^auto_delete=.*%auto_delete=${auto_delete}%" "${config_file}"
fi
if [ "${bark_device_key}" ]
then
   sed -i "s%^bark_device_key=.*%bark_device_key=${bark_device_key}%" "${config_file}"
fi
if [ "${bark_server}" ]
then
   sed -i "s%^bark_server=.*%bark_server=${bark_server}%" "${config_file}"
fi
if [ "${convert_heic_to_jpeg}" ]
then
   sed -i "s%^convert_heic_to_jpeg=.*%convert_heic_to_jpeg=${convert_heic_to_jpeg}%" "${config_file}"
fi
if [ "${debug_logging}" ]
then
   sed -i "s%^debug_logging=.*%debug_logging=${debug_logging}%" "${config_file}"
fi
if [ "${delete_accompanying}" ]
then
   sed -i "s%^delete_accompanying=.*%delete_accompanying=${delete_accompanying}%" "${config_file}"
fi
if [ "${delete_after_download}" ]
then
   sed -i "s%^delete_after_download=.*%delete_after_download=${delete_after_download}%" "${config_file}"
fi
if [ "${delete_empty_directories}" ]
then
   sed -i "s%^delete_empty_directories=.*%delete_empty_directories=${delete_empty_directories}%" "${config_file}"
fi
if [ "${delete_notifications}" ]
then
   sed -i "s%^delete_notifications=.*%delete_notifications=${delete_notifications}%" "${config_file}"
fi
if [ "${dingtalk_token}" ]
then
   sed -i "s%^dingtalk_token=.*%dingtalk_token=${dingtalk_token}%" "${config_file}"
fi
if [ "${directory_permissions}" ]
then
   sed -i "s%^directory_permissions=.*%directory_permissions=${directory_permissions}%" "${config_file}"
fi
if [ "${discord_id}" ]
then
   sed -i "s%^discord_id=.*%discord_id=${discord_id}%" "${config_file}"
fi
if [ "${discord_token}" ]
then
   sed -i "s%^discord_token=.*%discord_token=${discord_token}%" "${config_file}"
fi
if [ "${download_notifications}" ]
then
   sed -i "s%^download_notifications=.*%download_notifications=${download_notifications}%" "${config_file}"
fi
if [ "${download_path}" ]
then
   sed -i "s%^download_path=.*%download_path=${download_path}%" "${config_file}"
fi
if [ "${fake_user_agent}" ]
then
   sed -i "s%^fake_user_agent=.*%fake_user_agent=${fake_user_agent}%" "${config_file}"
fi
if [ "${file_match_policy}" ]
then
   sed -i "s%^file_match_policy=.*%file_match_policy=${file_match_policy}%" "${config_file}"
fi
if [ "${file_permissions}" ]
then
   sed -i "s%^file_permissions=.*%file_permissions=${file_permissions}%" "${config_file}"
fi
if [ "${folder_structure}" ]
then
   sanitised_folder_structure="${folder_structure//\//\\/}"
   sed -i "s@^folder_structure=.*@folder_structure=${sanitised_folder_structure}@" "${config_file}"
fi
if [ "${force_gid}" ]
then
   sed -i "s%^force_gid=.*%force_gid=${force_gid}%" "${config_file}"
fi
if [ "${gotify_app_token}" ]
then
   sed -i "s%^gotify_app_token=.*%gotify_app_token=${gotify_app_token}%" "${config_file}"
fi
if [ "${gotify_https}" ]
then
   sed -i "s%^gotify_https=.*%gotify_https=${gotify_https}%" "${config_file}"
fi
if [ "${gotify_server_url}" ]
then
   sed -i "s%^gotify_server_url=.*%gotify_server_url=${gotify_server_url}%" "${config_file}"
fi
if [ "${group}" ]
then
   sed -i "s%^group=.*%group=${group}%" "${config_file}"
fi
if [ "${group_id}" ]
then
   sed -i "s%^group_id=.*%group_id=${group_id}%" "${config_file}"
fi
if [ "${icloud_china}" ]
then
   sed -i "s%^icloud_china=.*%icloud_china=${icloud_china}%" "${config_file}"
fi
if [ "${iyuu_token}" ]
then
   sed -i "s%^iyuu_token=.*%iyuu_token=${iyuu_token}%" "${config_file}"
fi
if [ "${jpeg_path}" ]
then
   sed -i "s%^jpeg_path=.*%jpeg_path=${jpeg_path}%" "${config_file}"
fi
if [ "${jpeg_quality}" ]
then
   sed -i "s%^jpeg_quality=.*%jpeg_quality=${jpeg_quality}%" "${config_file}"
fi
if [ "${keep_icloud_recent_days}" ]
then
   sed -i "s%^keep_icloud_recent_days=.*%keep_icloud_recent_days=${keep_icloud_recent_days}%" "${config_file}"
fi
if [ "${keep_icloud_recent_only}" ]
then
   sed -i "s%^keep_icloud_recent_only=.*%keep_icloud_recent_only=${keep_icloud_recent_only}%" "${config_file}"
fi
if [ "${keep_unicode}" ]
then
   sed -i "s%^keep_unicode=.*%keep_unicode=${keep_unicode}%" "${config_file}"
fi
if [ "${libraries_with_dates}" ]
then
   sed -i "s%^libraries_with_dates=.*%libraries_with_dates=${libraries_with_dates}%" "${config_file}"
fi
if [ "${live_photo_mov_filename_policy}" ]
then
   sed -i "s%^live_photo_mov_filename_policy=.*%live_photo_mov_filename_policy=${live_photo_mov_filename_policy}%" "${config_file}"
fi
if [ "${live_photo_size}" ]
then
   sed -i "s%^live_photo_size=.*%live_photo_size=${live_photo_size}%" "${config_file}"
fi
if [ "${nextcloud_delete}" ]
then
   sed -i "s%^nextcloud_delete=.*%nextcloud_delete=${nextcloud_delete}%" "${config_file}"
fi
if [ "${nextcloud_upload}" ]
then
   sed -i "s%^nextcloud_upload=.*%nextcloud_upload=${nextcloud_upload}%" "${config_file}"
fi
if [ "${nextcloud_url}" ]
then
   sed -i "s%^nextcloud_url=.*%nextcloud_url=${nextcloud_url}%" "${config_file}"
fi
if [ "${nextcloud_username}" ]
then
   sed -i "s%^nextcloud_username=.*%nextcloud_username=${nextcloud_username}%" "${config_file}"
fi
if [ "${nextcloud_password}" ]
then
   sed -i "s%^nextcloud_password=.*%nextcloud_password=${nextcloud_password}%" "${config_file}"
fi
if [ "${notification_days}" ]
then
   sed -i "s%^notification_days=.*%notification_days=${notification_days}%" "${config_file}"
fi
if [ "${notification_type}" ]
then
   sed -i "s%^notification_type=.*%notification_type=${notification_type}%" "${config_file}"
fi
if [ "${photo_album}" ]
then
   sed -i "s%^photo_album=.*%photo_album=\"${photo_album}\"%" "${config_file}"
fi
if [ "${photo_library}" ]
then
   sed -i "s%^photo_library=.*%photo_library=${photo_library}%" "${config_file}"
fi
if [ "${photo_size}" ]
then
   sed -i "s%^photo_size=.*%photo_size=${photo_size}%" "${config_file}"
fi
if [ "${prowl_api_key}" ]
then
   sed -i "s%^prowl_api_key=.*%prowl_api_key=${prowl_api_key}%" "${config_file}"
fi
if [ "${pushover_sound}" ]
then
   sed -i "s%^pushover_sound=.*%pushover_sound=${pushover_sound}%" "${config_file}"
fi
if [ "${pushover_token}" ]
then
   sed -i "s%^pushover_token=.*%pushover_token=${pushover_token}%" "${config_file}"
fi
if [ "${pushover_user}" ]
then
   sed -i "s%^pushover_user=.*%pushover_user=${pushover_user}%" "${config_file}"
fi
if [ "${recent_only}" ]
then
   sed -i "s%^recent_only=.*%recent_only=${recent_only}%" "${config_file}"
fi
if [ "${set_exif_datetime}" ]
then
   sed -i "s%^set_exif_datetime=.*%set_exif_datetime=${set_exif_datetime}%" "${config_file}"
fi
if [ "${sideways_copy}" ]
then
   sed -i "s%^sideways_copy_videos=.*%sideways_copy_videos=${sideways_copy}%" "${config_file}"
fi
if [ "${sideways_copy_mode}" ]
then
   sed -i "s%^sideways_copy_videos_mode=.*%sideways_copy_videos_mode=${sideways_copy_mode}%" "${config_file}"
fi
if [ "${silent_file_notifications}" ]
then
   sed -i "s%^silent_file_notifications=.*%silent_file_notifications=${silent_file_notifications}%" "${config_file}"
fi
if [ "${single_pass}" ]
then
   sed -i "s%^single_pass=.*%single_pass=${single_pass}%" "${config_file}"
fi
if [ "${skip_album}" ]
then
   sed -i "s%^skip_album=.*%skip_album=\"${skip_album}\"%" "${config_file}"
fi
if [ "${skip_library}" ]
then
   sed -i "s%^skip_library=.*%skip_library=\"${skip_library}\"%" "${config_file}"
fi
if [ "${skip_check}" ]
then
   sed -i "s%^skip_check=.*%skip_check=${skip_check}%" "${config_file}"
fi
if [ "${skip_download}" ]
then
   sed -i "s%^skip_download=.*%skip_download=${skip_download}%" "${config_file}"
fi
if [ "${skip_live_photos}" ]
then
   sed -i "s%^skip_live_photos=.*%skip_live_photos=${skip_live_photos}%" "${config_file}"
fi
if [ "${skip_videos}" ]
then
   sed -i "s%^skip_videos=.*%skip_videos=${skip_videos}%" "${config_file}"
fi
if [ "${startup_notification}" ]
then
   sed -i "s%^startup_notification=.*%startup_notification=${startup_notification}%" "${config_file}"
fi
if [ "${download_delay}" ]
then
   sed -i "s%^download_delay=.*%download_delay=${download_delay}%" "${config_file}"
fi
if [ "${download_interval}" ]
then
   sed -i "s%^download_interval=.*%download_interval=${download_interval}%" "${config_file}"
fi
if [ "${synology_ignore_path}" ]
then
   sed -i "s%^synology_ignore_path=.*%synology_ignore_path=${synology_ignore_path}%" "${config_file}"
fi
if [ "${synology_photos_app_fix}" ]
then
   sed -i "s%^synology_photos_app_fix=.*%synology_photos_app_fix=${synology_photos_app_fix}%" "${config_file}"
fi
if [ "${telegram_chat_id}" ]
then
   sed -i "s%^telegram_chat_id=.*%telegram_chat_id=${telegram_chat_id}%" "${config_file}"
fi
if [ "${telegram_http}" ]
then
   sed -i "s%^telegram_http=.*%telegram_http=${telegram_http}%" "${config_file}"
fi
if [ "${telegram_polling}" ]
then
   sed -i "s%^telegram_polling=.*%telegram_polling=${telegram_polling}%" "${config_file}"
fi
if [ "${telegram_server}" ]
then
   sed -i "s%^telegram_server=.*%telegram_server=${telegram_server}%" "${config_file}"
fi
if [ "${telegram_token}" ]
then
   sed -i "s%^telegram_token=.*%telegram_token=${telegram_token}%" "${config_file}"
fi
if [ "${trigger_nextlcoudcli_download}" ]
then
   sed -i "s%^trigger_nextlcoudcli_download=.*%trigger_nextlcoudcli_download=${trigger_nextlcoudcli_download}%" "${config_file}"
fi
if [ "${until_found}" ]
then
   sed -i "s%^until_found=.*%until_found=${until_found}%" "${config_file}"
fi
if [ "${user}" ]
then
   sed -i "s%^user=.*%user=${user}%" "${config_file}"
fi
if [ "${user_id}" ]
then
   sed -i "s%^user_id=.*%user_id=${user_id}%" "${config_file}"
fi
if [ "${video_path}" ]
then
   sed -i "s%^video_path=.*%video_path=${video_path}%" "${config_file}"
fi
if [ "${webhook_https}" ]
then
   sed -i "s%^webhook_https=.*%webhook_https=${webhook_https}%" "${config_file}"
fi
if [ "${webhook_id}" ]
then
   sed -i "s%^webhook_id=.*%webhook_id=${webhook_id}%" "${config_file}"
fi
if [ "${webhook_path}" ]
then
   sed -i "s%^webhook_path=.*%webhook_path=${webhook_path}%" "${config_file}"
fi
if [ "${webhook_port}" ]
then
   sed -i "s%^webhook_port=.*%webhook_port=${webhook_port}%" "${config_file}"
fi
if [ "${webhook_server}" ]
then
   sed -i "s%^webhook_server=.*%webhook_server=${webhook_server}%" "${config_file}"
fi
if [ "${webhook_insecure}" ]
then
   sed -i "s%^webhook_insecure=.*%webhook_insecure=${webhook_insecure}%" "${config_file}"
fi
if [ "${wecom_id}" ]
then
   sed -i "s%^wecom_id=.*%wecom_id=${wecom_id}%" "${config_file}"
fi
if [ "${wecom_proxy}" ]
then
   sed -i "s%^wecom_proxy=.*%wecom_proxy=${wecom_proxy}%" "${config_file}"
fi
if [ "${wecom_secret}" ]
then
   sed -i "s%^wecom_secret=.*%wecom_secret=${wecom_secret}%" "${config_file}"
fi
if [ "${msmtp_host}" ]
then
   sed -i "s%^msmtp_host=.*%msmtp_host=${msmtp_host}%" "${config_file}"
fi
if [ "${msmtp_port}" ]
then
   sed -i "s%^msmtp_port=.*%msmtp_port=${msmtp_port}%" "${config_file}"
fi
if [ "${msmtp_user}" ]
then
   sed -i "s%^msmtp_user=.*%msmtp_user=${msmtp_user}%" "${config_file}"
fi
if [ "${msmtp_from}" ]
then
   sed -i "s%^msmtp_from=.*%msmtp_from=${msmtp_from}%" "${config_file}"
fi
if [ "${msmtp_pass}" ]
then
   sed -i "s%^msmtp_pass=.*%msmtp_pass=${msmtp_pass}%" "${config_file}"
fi
if [ "${msmtp_to}" ]
then
   sed -i "s%^msmtp_to=.*%msmtp_to=${msmtp_to}%" "${config_file}"
fi
if [ "${msmtp_tls}" ]
then
   sed -i "s%^msmtp_tls=.*%msmtp_tls=${msmtp_tls}%" "${config_file}"
fi
if [ "${msmtp_args}" ]
then
   sed -i "s%^msmtp_args=.*%msmtp_args=${msmtp_args}%" "${config_file}"
fi
if [ "${agentid}" ]
then
   sed -i "s%^agentid=.*%agentid=${agentid}%" "${config_file}"
fi
if [ "${touser}" ]
then
   sed -i "s%^touser=.*%touser=${touser}%" "${config_file}"
fi
if [ "${content_source_url}" ]
then
   sed -i "s%^content_source_url=.*%content_source_url=${content_source_url}%" "${config_file}"
fi
if [ "${name}" ]
then
   sed -i "s%^name=.*%name=${name}%" "${config_file}"
fi
if [ "${media_id_startup}" ]
then
   sed -i "s%^media_id_startup=.*%media_id_startup=${media_id_startup}%" "${config_file}"
fi
if [ "${media_id_download}" ]
then
   sed -i "s%^media_id_download=.*%media_id_download=${media_id_download}%" "${config_file}"
fi
if [ "${media_id_delete}" ]
then
   sed -i "s%^media_id_delete=.*%media_id_delete=${media_id_delete}%" "${config_file}"
fi
if [ "${media_id_expiration}" ]
then
   sed -i "s%^media_id_expiration=.*%media_id_expiration=${media_id_expiration}%" "${config_file}"
fi
if [ "${media_id_warning}" ]
then
   sed -i "s%^media_id_warning=.*%media_id_warning=${media_id_warning}%" "${config_file}"
fi

# Set case sensitive variables to lowercase
notification_type_lc="$(grep "^notification_type=" /config/icloudpd.conf | awk -F= '{print $2}' | tr '[:upper:]' '[:lower:]')"
if [ "${notification_type_lc}" ]
then
   sed -i "s%^notification_type=.*%notification_type=${notification_type_lc}%" "${config_file}"
fi

# Remove trailing slashes on directories
download_path_temp="$(grep "^download_path=" /config/icloudpd.conf | awk -F= '{print $2}')"
if [ "${download_path_temp}" ]
then
   sed -i "s#^download_path=.*#download_path=${download_path_temp%/}#" "${config_file}"
fi
jpeg_path_temp="$(grep "^jpeg_path=" /config/icloudpd.conf | awk -F= '{print $2}')"
if [ "${jpeg_path_temp}" ]
then
   sed -i "s#^jpeg_path=.*#jpeg_path=${jpeg_path_temp%/}#" "${config_file}"
fi
video_path_temp="$(grep "^video_path=" /config/icloudpd.conf | awk -F= '{print $2}')"
if [ "${video_path_temp}" ]
then
   sed -i "s%^video_path=.*%video_path=${video_path_temp%/}%" "${config_file}"
fi
nextcloud_url_temp="$(grep "^nextcloud_url=" /config/icloudpd.conf | awk -F= '{print $2}')"
if [ "${nextcloud_url_temp}" ]
then
   sed -i "s%^nextcloud_url=.*%nextcloud_url=${nextcloud_url_temp%/}%" "${config_file}"
fi
nextcloud_target_dir_temp="$(grep "^nextcloud_target_dir=" /config/icloudpd.conf | awk -F= '{print $2}')"
if [ "${nextcloud_target_dir_temp}" ]
then
   sed -i "s%^nextcloud_target_dir=.*%nextcloud_target_dir=${nextcloud_target_dir_temp%/}%" "${config_file}"
fi

# Update config file
mv "${config_file}" "${config_file}.tmp"
sort "${config_file}.tmp" --output="${config_file}"
sed -i '/^$/d' "${config_file}.tmp"
chmod --reference="${config_file}.tmp" "${config_file}"
rm "${config_file}.tmp"

sed -i 's/=True/=true/gI' "${config_file}"
sed -i 's/=False/=false/gI' "${config_file}"
sed -i 's/debug_logging=AAAAA/debug_logging=false/' "${config_file}"
sed -i 's/authentication_type=2FA/authentication_type=MFA/' "${config_file}"
sed -i '/keep_recent_days=/d' "${config_file}"