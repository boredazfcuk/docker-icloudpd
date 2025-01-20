## Environment variables
Environment variables can, for the time being, be used to configure the Docker container. However, configuring containers by using variables is deprecated and will be removed in future versions.
When the container is first started, it will write a default configuration file "/config/icloudpd.conf" and the variables will be loaded from there. I you find that some things are still being set, even though you have removed the variables from the container, it could be that they are still located in the configuration file.

## CONFIGURATION OPTIONS
**apple_id**: This is the Apple ID that will be used when downloading files. This option is mandatory

**user**: This is name of the user account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user on the host system for which you want to download files for. This user will be set as the owner of all downloaded files. Default: 'user'. This option is also used as the trigger for remotly initiated sync. Simply send your user name as a message to the Telegram chat, icoudpd will see it, and start a manual sync.

**user_id**: This is the User ID number of the above user account. This can be any number that isn't already in use. Ideally, you should set this to be the same ID number as the user's ID on the host system. This will avoid permissions issues if syncing to your host's home directory. Default: '1000'.

**group**: This is name of the group account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user's primary group on the host system. This group will be set as the group for all downloaded files. Default: 'group'.

**group_id**: This is the Group ID number of the above group. This can be any number that isn't already in use. Ideally, you should set this to be the same Group ID number as the user's primary group on the host system. Default: '1000'.

**force_gid**: If this configuration option is set it will allow the group to be created with a pre-existing group id. This may be handy if your group id clashes with a system group insude the docker container, however, if may have undesired permissions issues. Please use with caution.

**TZ**: Sets the local timezone and is required to calculate timestamps. Default: 'UTC'. If you are unsure of your timezone, the list can be found here: https://nodatime.org/TimeZones. The value you need to set is listed in the "Zone ID" column of the table.

**download_path**: This is the directory to which files will be downloaded from iCloud. Default: "/home/${user}/iCloud".

**synchronisation_interval**: This is the number of seconds between synchronisations. It can be set to the following periods: 21600 (6hrs), 43200 (12hrs), 86400 (24hrs), 129600 (36hrs), 172800 (48hrs) and 604800 (7 days). If this configuration option is not set to one of these values, it will default to 86400 seconds. Be careful if setting a short synchronisation period. Apple have a tendency to throttle connections that are hitting their server too often. I find that every 24hrs is fine. My phone will upload files to the cloud immediately, so if I lose my phone the photos I've taken that day will still be safe in the cloud, and the container will download those photos when it runs in the evening. Setting a value less than 12 hours will display a warning as Apple may throttle you.

**synchronisation_delay**: This is the number of minutes to delay the first synchronisation. This is so that you can stagger the synchronisations of multiple containers. Default: 0. It has a maximum setting of 60.

**notification_days**: When your cookie is nearing expiration, this is the number of days in advance it should notify you. You will receive a single notification, per day, in the days running up to cookie expiration. Default: 7.

**authentication_type**: This is the type of authentication that is enabled on your iCloud account. Valid values are 'MFA' if you have multifactor authentication enabled or 'Web' if you do not. If 'Web' is specified, then cookie generation is not required. Default: 'MFA'.

**directory_permissions**: This specifies the permissions to set on the directories in your download destination. Default: 750.

**file_permissions**: This specifies the permissions to set on the files in your download destination. Default: 640.

**folder_structure**: This specifies the folder structure to use in your download destination directory. If this configuration option is not set, it will set {:%Y/%m/%d} as the default. Use **none** to download to a flat file structure. Changing this value will not re-organise your currently downloaded files. It will leave your current folder structure intact and download your entire stream again. I do not recommend using **none** or {:%Y} as these two may result in images not being downloaded. In iCloud, you can have two identically named files and it will be fine. Using this downloader, the first file downloaded will take that name and the second file will be ignored.

**albums_with_dates**: When albums are downloaded, they are downloaded into directories of the same name as the album. Setting this variable to **true** will then create sub folders according to the **folder_structure** variable. Default: false

**libraries_with_dates**: When libraries are downloaded, they are downloaded into directories of the same name as the library. Setting this variable to **true** will then create sub folders according to the **folder_structure** variable. Default: false

**skip_check**: Set this to **true** skip the check for new files. The check can have issues with large libraries, please set to **true** if you have more than a few thousand photos. Default: false.

**download_notifications**: specifies whether notifications with a short summary should be sent for file downloads. Default: true.

**delete_notifications**: Specifies whether notifications with a short summary should be sent for file deletions. Default: true.

**startup_notification**: Specifies whether the startup notification should be sent. Default: true.

**delete_accompanying**: Tells the script to delete files which accompany the HEIC files that are downloaded. These are the JPG files which are created if you have HEIC to JPG conversion enabled. They are also the \_HEVC.MOV files which make up part of a live photo. This feature deletes files from your disk. I'm not responsible for any data loss.

**delete_empty_directories**: Tells the script to delete any empty directories it finds in the download path. It will only run if **folder_structure** isn't set to 'none'

**set_exif_datetime**: Write the DateTimeOriginal exif tag from file creation date. Warning: Setting this option will alter the local file and result in the original being downloaded again, with a de-duplication suffix added to the name. Default: false.

**auto_delete**: Scans the "Recently Deleted" folder and deletes any files found in there. (If you restore the photo in iCloud, it will be downloaded again). Default: false.

**delete_after_download**: After a file is successfully downloaded it is moved to the Recenlty Deleted folder. This configuration option cannot be used in conjunction with **auto_delete**. Default: false.

**keep_icloud_recent_days**: Set this to an integer number to only keep the most recent *n* number of days. Setting this to 0 will remove all photos from iCloud. This configuration option cannot be used in conjunction with **delete_after_download**. Default: Not set (keep all).

**keep_icloud_recent_only**: Set this to **true** to enable the option above. Default: false

**photo_size**: Image size to download. Can be set to **original**, **medium**, **thumb**, **adjusted**, **alternative** or any combination of those five in a comma-separated string if multiple size types are to be downloaded e.g. **photo_size=original,adjusted**. Adjusted are the edited photos that can be made by using filters, or by using the markup tool in the Photos app. Alternative are RAW file types. Default: original.

**skip_live_photos**: If this is set, it will skip downloading live photos. Default: false.

**live_photo_size**: Live photo file size to download. Can be set to **original**, **medium** or **thumb**. If skip_live_photos is set, this setting is redundant. Default: original.

**skip_videos**: If this is set, it will skip downloading videos. Default: false.

**recent_only**: Set this to an integer number to only download this many recently added photos. Default: download all photos.

**until_found**: Set this to an integer number to only download the most recently added photos, until *n* number of previously downloaded consecutive photos are found. Default: download all photos.

**photo_album**: Set this to a comma delimited field to download photos from a photo album. Please note, if downloading from multiple albums, you need to enclose them in quotes in your /config/icloudpd.conf file e.g. photo_album="one,two,three and four" will download photos from three albums named "one", "two" and "three and four". When downloading photo albums, the folder structure will be set to be the name of the album eg "/home/boredazfcuk/iCloud/one/IMG_0001.HEIC", "/home/boredazfcuk/iCloud/two/IMG_0002.HEIC" and "/home/boredazfcuk/iCloud/three and four/IMG_0003.HEIC". Set  **photo_album="all albums"** in your configuration file /config/icloudpd.conf to download all albums. Please note: Due to a limitation in an upstream package, downloading from multiple albums will trigger multiple download runs. When Apple detect this, they may force a multifactor re-authentication. 

**photo_library**: Set this to a comma delimited field to download photos from a shared library. Please note, if downloading from multiple libraries, you need to enclose them in quotes in your /config/icloudpd.conf file e.g. photo_library="one,two,three and four" will download photos from three libraries named "one", "two" and "three and four". When downloading photo libraries, the folder structure will be set to be the name of the library eg "/home/boredazfcuk/iCloud/one/IMG_0001.HEIC", "/home/boredazfcuk/iCloud/two/IMG_0002.HEIC" and "/home/boredazfcuk/iCloud/three and four/IMG_0003.HEIC". Set  **photo_library="all libraries"** in your configuration file /config/icloudpd.conf to download all libraries. Please note: Due to a limitation in an upstream package, downloading from multiple libraries will trigger multiple download runs, and Apple may force a multifactor re-authentication.

**skip_album**: Use this option in conjunction with **photo_album** to skip certain albums e.g. **skip_album="All Photos,Time-lapse,Videos,Slo-mo,Bursts,Favorites,Panoramas,Screenshots,Live,Recently Deleted,Hidden"**

**skip_library**: Use this option in conjunction with **photo_library** to skip certain libraries e.g. **skip_libraries="PrimarySync,SharedSync-########-####-####-####-############"**

**photo_library**: Set this to the name of an iOS 16 shared library to download photos from that shared library.

**convert_heic_to_jpeg**: Set this to **true** to convert downloaded HEIC files to JPEG, while also retaining the original.

**jpeg_path**: Set this configuration option to specify a different location for the converted JPEGs. Default: "/home/${user}/iCloud", or **download_path** if not set, thereby placing the JPEG files alongside the HEIC files.

**jpeg_quality**: If HEIC to JPEG conversion is enabled, this configuration option will let you set the quality of the converted file by specifying a number from 0 (lowest quality) to 100 (highest quality). Default: 90.

**icloud_china**: Set this to **true** to use icloud.com.cn instead of icloud.com as the download source. Default: false.

**auth_china**: Set this to **true** to use icloud.com.cn instead of icloud.com for cookie generation. Default: false.

**fake_user_agent**: Set this to **true** to tell curl to use a fake user agent. This is required for some notification sites which do not allow curl to send notifications, IYUU for one. Sets user agent to: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0"

**synology_photos_app_fix**: Set this to **true** to touch files after download and trigger the Synology Photos app to index any newly created files.

**synology_ignore_path**: Set this to **true** to avoid warnings when trying to change **@eaDir** permissions for the extended attributes directories under Synology system.

**sideways_copy_videos**: Set this to **true** to have the container copy the downloaded videos to another directory. This directory must be specified in the **video_path** directory. Default: false

**sideways_copy_videos_mode**: Seto this to **copy** to have the **sideways_copy_videos** function copy files, leaving the original in place. Set this to **move** to have it move files to the destination directory. If **move** is specified, then **delete_after_download** must be set to **true**. This is to avoid a situation where all video files are moved out of the download folder, then re-downloaded when the next syncronisation occurs. By having **delete_after_download** set to **true** it means that each downloaded video is removed from iCloud after it's downloaded, so it would not be possible for the container to re-download the file after it is moved from the download directory.

**single_pass**: Set this to **true** to exit out after a single pass instead of looping as per the synchronisation_interval. This way, the script can be scheduled to lauch on the host system using cron or another scheduling agent. If this option is used, it will automatically disable the download check. If using this configuration option, the restart policy of the container must be set to "no". If it is set to "always" then the container will instantly relaunch after the first run and you will hammer Apple's website.

**keep_unicode**: Set this to **true** to keep unicode chars in file names or set it to **false** to remove all non-ascii chars. Default: false.

**live_photo_mov_filename_policy**: Set this to **suffix** to add _HEVC to the suffix of the file name. Set it to **original** to set the filename the same as the photo. Default: suffix.

**align_raw**: For photo assets with raw and jpeg, treat raw always in the specified size: **original** (raw+jpeg), **alternative** (jpeg+raw) or **as-is** (unchanged). Default: as-is.

**file_match_policy**: Policy to identify existing files and de-duplicate. **name-size-dedup-with-suffix** appends file size to deduplicate. **name-id7**
adds asset id from iCloud to all file names and does not need de-duplication. Default: name-size-dedup-with-suffix.

**video_path**: 

# NEXTCLOUD CONFIGURATION VARIABLES

**nextcloud_delete**: Set this variable to **true** if you want to remove files from Nextcloud. This setting requires **auto_delete** to also be set to true. When a file is found in the 'Recently Deleted', the **auto_delete** function will remove the local file. If **nextcloud_delete** is also set to **true**, then it will remove that file from the Nextcloud server.

**nextcloud_password**: This is the password for the Nextcloud account you are syncing to

**nextcloud_target_dir**: This is the name of the root folder that you want to place files in. Please note, it is not possible to upload files to the root of a Nextcloud server at this time.

**nextcloud_upload**: Set this to **true** to upload files to a Nextcloud server

**nextcloud_url**: This is the URL of your Nextcloud server e.g. https://my.server.local/ or https://my.server.local/nextcloud/

**nextcloud_username**: This is the user name of the account that you want to upload the files to.

## NOTIFICATION CONFIGURATION VARIABLES

**notification_type**: This specifies the method that is used to send notifications. These are the options available **Prowl**, **Pushover**, **Telegram**, **Webhook**, **openhab**, **Dingtalk**, **Discord**, **IYUU**, **WeCom**, **Gotify**, **Bark**, **msmtp**. When the multifactor authentication cookie is within 7 days (default) of expiry, a notification will be sent upon synchronisation. No more than a single notification will be sent within a 24 hour period unless the container is restarted. This does not include the notification that is sent each time the container is started.

**notification_title**: This allows you to change the title which is sent on the notifications. This variable will default to **boredazfcuk/iCloudPD**.

**prowl_api_key**: Mandatory if notification_type set to 'Prowl'. This is the API key for your account as generated by the Prowl website.

**pushover_user**: Mandatory if notification_type set to 'Pushover'. This is the Pushover user key associated with your account.

**pushover_token**: Mandatory if notification_type set to 'Pushover'. This is the application API token. You will need to create an application by logging into your Pushover account and creating an application.

**pushover_sound**: Mandatory if notification_type set to 'Pushover' this variable can be set to customise the sound of the notification. Values for this variable can be found here: https://pushover.net/api#sounds

**telegram_token**: Mandatory if notification_type set to 'Telegram'. This is the token that was assigned to your account by The Botfather.

**telegram_chat_id**: Mandatory if notification_type set to 'Telegram'. This is the chat_id for your Telegram bot. If the bot is a standard user that messages you, the chat ID will be a positive integer number. If the bot is a member of a group, and sends messages to the group, the chat ID will be prefixed with a hyphen '-' character.

**telegram_silent_file_notifications**: Optional if notification_type set to 'Telegram'. Set this to **true** for the file download notifications to be sent silently. Default = false

**telegram_polling**: Optional if notification_type set to 'Telegram'. Set this to true to enable Telegram polling. This will check the Telegram chat for messages every 60 seconds. If the latest message is the user name, it will synchronise immediately

**telegram_server**: Optional if notification_type set to 'Telegram'. If Telegram is blocked in your country and you need to use a proxy server to access it, put the fully qualified domain name of the server here. e.g. proxy.server.com

**telegram_http**: Optional if notification_type set to 'Telegram'. If Telegram is retricted to HTTP only in your country, set this to **true** so that HTTP is used instead of HTTPS. Default = false

**webhook_server**: Mandatory if notification_type set to 'Webhook' or 'openhab' then this is the name of the server to connect to when sending webhook notifications.

**webhook_port**: Mandatory if notification_type set to 'Webhook' or 'openhab' then this is the port number to use when connecting to the webhook server. If this is not set, it will default to 8123.

**webhook_path**: Mandatory if notification_type set to 'Webhook' or 'openhab' then this is the path to use when connectiong to the webhook server. The path must start and end with a forward slash character. If this is not set, it will default to **/api/webhook/**. Openhab uses **"/rest/items/<itemname>/"**.

**webhook_id**: Mandatory if notification_type set to 'Webhook' or 'openhab' then this is the Webhook ID to use. Openhab uses "state".

**webhook_https**: If this is set to 'True' then the Webhook or openhab notification URL will use HTTPS, otherwise it will default to HTTP.

**webhook_body**: Adapt to different services. Homeassistant uses "data" in the body of the webhook request, Discord uses "content", IFTTT uses "value1", etc.. Defaults to "data".

**webhook_insecure**: Set to **true** to allow insecure https certificates, such as self-signed.

**dingtalk_token**: Mandatory if notification_type set to 'Dingtalk' then this is the access token generated by the Dingtalk application. In the Dingtalk application, go to 'Security Settings', select 'Custom Keywords' and set to to the same value as **notification_title**.

**discord_id**: This is the first half of the URL generated by Discord's webhook integration.  It will be all numbers.  Do not include any /

**discord_token**: This is the second half of the URL generated by Discords webhook integration.  Do no include any /

**iyuu_token**: Mandatory if notification_type set to 'IYUU'. This is the access token required to send messages.

**wecom_id**: Mandatory if notification_type set to 'WeCom'.企业微信通知，企业微信通知，企业ID / This is the CORPID associated with your account。企业微信通知配置也可参见[此项目链接](https://github.com/Alano-i/wecom-notification/tree/main/iCloudPD)

**wecom_secret**: Mandatory if notification_type set to 'WeCom'.企业微信通知，企业应用的Secret / This is the CORPSECRET associated with your account

**agentid**: Mandatory if notification_type set to 'WeCom'.企业微信通知，企业应用的id / Enterprise application id

**touser**: Mandatory if notification_type set to 'WeCom'.企业微信通知，接收通知的对象 / who receives notifications

**content_source_url**: Mandatory if notification_type set to 'WeCom'.企业微信通知，阅读原文跳转链接 / Click on the page link after "reading the original text"

**name**: Mandatory if notification_type set to 'WeCom'.企业微信通知，当前 Apple ID 所有人 / Current Apple ID owner

**wecom_proxy**: Optional. 企业微信通知，企业微信的代理,非必填,用来绕过企业微信的IP白名单 / Optional,Used to bypass the ip whitelist of WeCom

**media_id_startup**: Mandatory if notification_type set to 'WeCom'.企业微信通知，启动成功通知封面 / Image for Startup success

**media_id_download**: Mandatory if notification_type set to 'WeCom'.企业微信通知，下载通知封面 / Image for downloaded files

**media_id_delete**: Mandatory if notification_type set to 'WeCom'.企业微信通知，删除文件通知封面 / Image for deleted files

**media_id_expiration**: Mandatory if notification_type set to 'WeCom'.企业微信通知，cookie即将过期通知封面 / Image for cookie expiration

**media_id_warning**: Mandatory if notification_type set to 'WeCom'.企业微信通知，同步失败、cookiey已过期通知封面 / Image for cookie expired or failure

**gotify_app_token**: Mandatory if notification_type set to 'Gotify'. This is the app_token associated with your account.

**gotify_https**: If this is set to 'True' then the Gotify server URL will use HTTPS, otherwise it will default to HTTP.

**gotify_server_url**: Mandatory if notification_type set to 'Gotify'. This is the server name of your Gotify server e.g. server.domain.tld

**bark_device_key**: Mandatory if notification_type set to 'Bark'. This is the device key associated with your device.

**bark_server**: Mandatory if notification_type set to 'Bark'. This is the name of your Bark server. Please note that the port should not be included and currently the project only supports http.
If you use the official Bark server, please fill the field with `api.day.app`.

**msmtp_host**: Mandatory if notification_type set to `msmtp`. The domain of your smtp server

**msmtp_port**: Mandatory if notification_type set to `msmtp`. The port of the smtp service. Normally 465 or 587

**msmtp_tls**: Mandatory if notification_type set to `msmtp`. Set to `on` or `off` to enable or disable TLS encryption.

**msmtp_from**: Mandatory if notification_type set to `msmtp`. The sender's email address

**msmtp_user**: Mandatory if notification_type set to `msmtp`. The login username for your SMTP provider.

**msmtp_pass**: Mandatory if notification_type set to `msmtp`. The password for the login user

**msmtp_args**: Optional extra arguments for `msmtp` in case your mail provider has specific requirements. For example, `--tls-starttls=off`.

## VOLUME CONFIGURATION

This container requires a named volume mapped to /config. This is where is stores the authentication cookie. Without it, it will lose the cookie information each time the container is recreated.
It will download the photos to the "/home/${user}/iCloud" photos directory. You need to create a bind mount into the container at this point.

## FAILSAFE FEATURE

I have added a failsafe feature to this container so that it doesn't make any changes to the filesystem unless it can verify the volume it is writing to is mounted correctly. The container will look for a file called "/home/${user}/iCloud/.mounted" (please note the capitalisation of iCloud) in the download destination directory inside the container. If this file is not present, it will not download anything from iCloud. This way, if underlying disk/volume/whatever gets unmounted, sync will not occur and this prevents the script from filling up the root volume of the host. This file **MUST** be created manually and sync will not start without it.

## CREATING A CONTAINER

First off, create a dedicated network for your iCloudPD conter(s) as this overcomes some DNS and routing issues may occur if you use the legacy default network bridge that Docker creates. In this example, I've have told it to use the IP address subnet 192.168.115.1 - 192.168.115.254 and configured the gateway to be 192.168.115.254. You can use any subnet you like:

```
docker network create \
   --driver=bridge \
   --subnet=192.168.115.0/24 \
   --gateway=192.168.115.254 \
   --opt com.docker.network.bridge.name=icloudpd_br0 \
   icloudpd_bridge
```
Then create the container, connecting it to the new icloudpd network bridge. It should look something like this:

```
docker create \
   --name iCloudPD_boredazfcuk \
   --hostname icloudpd_boredazfcuk \
   --network icloudpd_bridge \
   --restart=always \
   --env TZ=Europe/London \
   --volume icloudpd_boredazfcuk_config:/config \
   --volume /home/boredazfcuk/iCloud:/home/boredazfcuk/iCloud \
   boredazfcuk/icloudpd
```

Note: Raspberry Pi users have reported that the container only functions correctly when the containes is created with the `--privileged` parameter.

Once you have created your container. The configurable environment variables will be listed in the configuration file located in `/config/icloudpd.conf`

## CONFIGURING A PASSWORD

Once the container has been created, you should connect to it and run `/usr/local/bin/sync-icloud.sh --Initialise`. This will then take you through the process of adding your password to the container's keyring. It will also take you through generating a cookie that will allow the container to download the photos.

If you launch a container without initialising it first, you will receive this error message:
```
ERROR    Keyring file /config/python_keyring/keyring_pass.cfg does not exist.
INFO      - Please add the your password to the system keyring using the --Initialise script command line option.
INFO      - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise
INFO      - Example: docker exec -it icloudpd sync-icloud.sh --Initialise
INFO     Restarting in 5 minutes...
```

As per the error, the container needs to be initialised by using the --Initialise command line option. With the first container still running, connect to it and launch the initialisation process by running the following at the terminal prompt (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Initialise`

You will then be asked to log in to icloud.com, with your current Apple ID and password, and will be prompted to enter a multifactor authentication code which will be sent via SMS. Once that is confirmed, the password will be added to the keyring.

If you do not have an authentication cookie, and you have multifactor authentication enabled on your account, you will be taken to the cookie generation process immediately after.

## MULTIFACTOR AUTHENTICATION

If your Apple ID account has multifactor authentication enabled, you will see that the container waits for a multifactor authentication cookie to be created:
```
ERROR    Cookie does not exist."
INFO      - Please create your cookie using the --Initialise script command line option."
INFO      - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
INFO      - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
INFO     Restarting in 5 minutes..."
```

Without this cookie, synchronisation cannot be started.

As per the error, the container needs to be initialised by using the --Initialise command line option. With the first container still running, connect to it and launch the initialisation process by running the following at the terminal prompt (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Initialise`

After that, the script will log into the icloud.com website and save the MFA cookie. Your iDevice will ask you if you want to allow or deny the login. When you allow the login, you will be give a 6-digit approval code. Enter the approval code when prompted.

The process should look similar to this:

```
2020-08-06 16:45:58 INFO     ***** boredazfcuk/icloudpd container for icloud_photo_downloader started *****
2020-08-06 16:45:58 INFO     Alpine Linux v3.12
2020-08-06 16:45:58 INFO     Interactive session: true
2020-08-06 16:45:58 INFO     Local user: user:1000
2020-08-06 16:45:58 INFO     Local group: group:1000
2020-08-06 16:45:58 INFO     LAN IP Address: 192.168.20.1
2020-08-06 16:45:58 INFO     Apple ID: email@address.com
2020-08-06 16:45:58 INFO     Authentication Type: MFA
2020-08-06 16:45:58 INFO     Cookie path: /config/emailaddresscom
2020-08-06 16:45:58 INFO     Cookie expiry notification period: 7
2020-08-06 16:45:58 INFO     Download destination directory: /home/user/iCloud
2020-08-06 16:45:58 INFO     Folder structure: {:%Y}
2020-08-06 16:45:58 INFO     Directory permissions: 750
2020-08-06 16:45:58 INFO     File permissions: 640
2020-08-06 16:45:58 INFO     Synchronisation interval: 43200
2020-08-06 16:45:58 INFO     Time zone: Europe/London
2020-08-06 16:45:58 INFO     Adding password to keyring...
Enter iCloud password for email@address.com:
Save password in keyring?  [y/N]: y
Two-step authentication required. Your trusted devices are:
  0: SMS to 07********
Which device would you like to use? [0]: 0
Please enter validation code: 123456
2020-08-06 16:47:04 INFO     Using password stored in keyring
2020-08-06 16:47:04 INFO     Generate MFA cookie with password: usekeyring
2020-08-06 16:47:04 INFO     Check for new files using password stored in keyring...
  0: SMS to 07********
  1: Enter two-factor authentication code
Please choose an option: [0]: 1
Please enter two-factor authentication code: 123456
2020-08-06 16:47:30 INFO     Multifactor authentication cookie generated. Sync should now be successful.
```

This will then place a multifactor authentication cookie into the /config folder of the container. This cookie will expire after three months. After it has expired, you will need to re-initialise the container again.

After this, the container should start downloading your photos.

Dockerfile has a health check which will change the status of the container to 'unhealthy' if the cookie is due to expire within a set number of days (notification_days) and also if the download fails.

## MULTIFACTOR RE-AUTHENTICATION
Every 30 days, the cookie will expire and need to be re-authenticated. This can be done by running the re-authentication script:

```
docker container exec -it reauth.sh
```

It will then launch the re-authentication process, presenting you with an MFA code on your iDevice and asking for this new code on the command line. e.g:

```
2024-03-27 22:21:33 DEBUG    Authenticating...
2024-03-27 22:21:35 INFO     Two-step/two-factor authentication is required (2fa)
Please enter two-factor authentication code: 123456
2024-03-27 22:21:55 WARNING  Failed to parse response with JSON mimetype
2024-03-27 22:21:57 INFO     Great, you're all set up. The script can now be run without user interaction until 2SA expires.
You can set up email notifications for when the two-step authentication expires.
(Use --help to view information about SMTP options.)
2024-03-27 22:21:57 INFO     Authentication completed successfully
```

# TELEGRAM 2-WAY COMMUNICATIONS
## Remote Synchronisation
If you are using Telegram as your notification application, you can now send messages to the chat bot, which the container will read, and then take the appropriate action. If you simply message the chatbot with the user that you have configured in the **user** variable, it will pick that up and force a synchronisation. So if you're down the pub with your mates, take a bunch of pics that you really like, simply message `boredazfcuk` (or whatever you've configured your user variable to be) to the Telegram bot and it will force a synchronisation, downloading your new photos within the next few minutes.

## Remote Re-authentication
Apple have recently reduced the re-authentication tim from 90 days to 30 days. This means connecting to your container, re-initialising it and completing multi-factor authentication. If I am out of the house and my cookie expires, I would need to wait until I get home, faff about with the whole process I just described. Now, you can message your container in a similar manner to the remote syncronisation, but adding `auth` to the end of the message, so for example `boredazfcuk auth`. After you have done this, I find it is best to start typing another message starting `boredazfcuk ` (note the space) and then changing the keyboard to number input. The container should pick up this instruction within a minute and it will message you back asking for the MFA code. It will start the re-authentication process and your iDevice will display a popup to `allow` or `deny` the connection. Click `allow` and you will be presented with your multi-factor authentication code. Memorise this code and add it to the end of your message, like `boredazfcuk 123456` and hit send. The container will then use this code to re-initialise your cookie and start downloading your photos again. One word of caution though... Literally every company on the planet tells you never to share this code with anyone. I put this feature in because... well... I trust me. I don't believe in putting blind faith in other though. So neither should you. Feel free to read the source code, so you can make sure it's not doing anything nefarious, by checking it yourself. I understand that not everyone can code though, so if you don't trust it, that's totally OK, probably a good choice on your behalf. To be fair, I'm just a dude with an IT hobby. I couldn't care less about your iCloud account, your contacts, or the pictures of your cat/dog. I just hope this makes you life better in some tiny way.

## COMMAND LINE PARAMETERS

There are currently a number of command line parameters are available to use with the sync-icloud.sh script. These are:

**--Convert-All-HEICs**
This command line option will check for HEIC files that do not have an accompanying JPEG file. If it finds a HEIC that does not have an accompaying JPEG file, it will create it. This can be used to add JPEGs for previously downloaded libraries. The easiest way to run this is to connect to the running container and executing the script.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Convert-All-HEICs`

**--Force-Convert-All-HEICs**
This command line option is the same as the above option but it will overwrite any JPEG files that are already there. This will result in data loss if the downloaded JPEG files have been edited. For this reason, there is a 2 minute delay before this option runs. This gives you time to stop the container, or cancel the script, before it runs. This option is required as the heif-tools conversion utility had a bug that over-rotates the JPEG files. This means the orientation does not match the HEIC file. The heif-tools package has now been replaced by the ImageMagick package which doesn't have this problem. This command line option can be used to re-convert all your HEIC files to JPEG, overwriting the incorrectly oriented files with correctly oriented ones.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Force-Convert-All-HEICs`

**--Force-Convert-All-mnt-HEICs**
This command line option is the same as the above option but it will overwrite any JPEG files that it finds in the /mnt subdirectory. This will result in data loss if the downloaded JPEG files have been edited. For this reason, there is a 2 minute delay before this option runs. This gives you time to stop the container, or cancel the script, before it runs. This option is required as the heif-tools conversion utility had a bug that over-rotates the JPEG files. This means the orientation does not match the HEIC file. The heif-tools package has now been replaced by the ImageMagick package which doesn't have this problem. This command line option can be used to re-convert all your HEIC files to JPEG, overwriting the incorrectly oriented files with correctly oriented ones. This option can be used to correct JPG files that have been archived and removed from your iCloud photostream. Just mount the target directory (or directories) into the /mnt subdirectoy and the script with this command.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Force-Convert-All-mnt-HEICs`

**--Remove-All-JPGs**
This command line option removes all the JPEG files which have a matching HEIC. My day-2-day laptop is Windows 11 and HEIC support is now baked into the OS. I've no need for JPGs anymore as I can view the HEICs and their thumbnails without issue. I created this to just purge all the JPEGs which have a HEIC with a matching filename. This could well remove JPEGs that have matching named HEICs, but are actually different photos. Oh well.

**--Correct-JPEG-Time-Stamps**
This command line option will correct the timestamps of JPEG files that do not match their accompanying HEIC files. Due to an omission, previous versions of my script never set the time stamp. This command line option will correct this issue.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Correct-JPEG-Time-Stamps`

**--Initialise** | **--Initialize** | **--init**
This command line option will allow you to add your password to the system keyring. It will also force the creation of a new two-factor authentication cookie.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Initialise`

**--Remove-Keyring**
This command line option will delete the system keyring file. You will need to run this if you change your Apple ID password.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Remove-Keyring`

**--Enable-Debugging**
This command line option will edit the config file so that debugging is enabled. This will automatically be picked up the next time a synchronisation takes place. There should be no need to restart the container
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Enable-Degugging`

**--Disable-Debugging**
This command line option will edit the config file so that debugging is disabled. This will automatically be picked up the next time a synchronisation takes place. There should be no need to restart the container
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Disable-Degugging`

**--Upload-Library-To-Nextcloud**
This command line option will upload your entire library to the Nextcloud server. First, it will scan your download directory, then replicate the directory structure on the Nextcloud server. Once this is complete, it will proceed upload the files to these directories.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Upload-Library-To-Nextcloud`

**--Sideways-Copy-All-Videos**
This command will copy all the videos in your download path to the location specified in the **video_path** variable. It will check the value of the **sideways_copy_all_videos_mode** variable to determine the copy mode, which can be either 'copy' or 'move'. If the copy mode is set to 'move' then the **delete_after_download** vairable must also be set to **true**. This is because moving the vidoes out of the the main download location will cause icloudpd to re-download the videos from iCloud. If **delete_after_download** is set, then iCloud should be empty, so the endless loop of downloading videos should not occurr.

**--List-Albums**
This commmand will list the names of the albums available to download
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --List-Albums`

**--List-Libraries**
This command will list the names of the libraries available to download
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --List-Libraries`

## HEALTH CHECK

I have built in a health check for this container. If the script detects a download error the container will be marked as unhealthy. You can then configure this container: https://hub.docker.com/r/willfarrell/autoheal/ to monitor iCloudPD and restart the unhealthy container. Please note, if your MFA cookie expires, the container will be marked as unhealthy, and will be restarted by the authoheal container every five minutes or so... This can lead to a lot of notifications if it happens while you're asleep!

## TROUBLESHOOTING

The app which runs inside this container connects to iCloud.com website and downloads the files it finds in there. Basically the same way as you would if you were downloading the files in your web browser, as Apple does not provide the capability to do this via an API (gotta love Apple's walled-garden). This is problematic because if the website changes at all, it throws the downloader out due to the website is doing something unexpected. There are many reasons that the website can change, for example, if somebody attempts to brute-force your account, you will be prompted to confirm your security questions the next time you log in. Accounts without two-factor authentication enabled will periodically receive a prompt upon login about upgrading the account's security.

If you have enabled Apple's Advanced Data Protection feature in iOS 16.2, you will need to disable it. This feature encrypts your photos on Apples servers and disables photo access on icloud.com which is required for this container. This results in you only being able to access your photos from your trusted Apple devices. There is an option to allow access to icloud.com for an hour at a time, but currently, an upstream dependency does not support this.

If your container starts erroring out all of a sudden, the first thing to do is to log into iCloud.com and check that there isn't some pop-up notification which needs clearing. If that doens't work, then try re-initialising your container. For larger libraries with thousands of images, disabling the download check is also a requirement, so please try that.
