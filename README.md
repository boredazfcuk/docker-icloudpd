# docker-icloudpd
An Alpine Linux Docker container for ndbroadbent's iCloud Photos Downloader. I use it for syncing the photo streams of all the iDevices in my house back to my server because it's the only way of backing up multiple devices to a single location. It uses the system keyring to securely store credentials, has HEIC to JPG conversion capability, and supports Telegram, Prowl, Pushover, WebHook, DingTalk & Discord notifications.

## MANDATORY ENVIRONMENT VARIABLES
**apple_id**: This is the Apple ID that wil lbe used when downloading files.

## DEFAULT ENVIRONMENT VARIABLES

**user**: This is name of the user account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user on the host system for which you want to download files for. This user will be set as the owner of all downloaded files. If this variable is not set, it will default to 'user'.

**user_id**: This is the User ID number of the above user account. This can be any number that isn't already in use. Ideally, you should set this to be the same ID number as the user's ID on the host system. This will avoid permissions issues if syncing to your host's home directory. If this variable is not set, it will default to '1000'.

**group**: This is name of the group account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user's primary group on the host system. This This group will be set as the group for all downloaded files. If this variable is not set, it will default to 'group'.

**group_id**: This is the Group ID number of the above group. This can be any number that isn't already in use. Ideally, you should set this to be the same Group ID number as the user's primary group on the host system. If this variable is not set, it will default to '1000'.

**force_gid**: If this variable is set it will allow the group to be created with a pre-existing group id. This may be handy if your group id clashes with a system group insude the docker container, however, if may have undesired permissions issues. Please use with caution.

**TZ**: This is the local timezone and is required to calculate timestamps. If this variable is not set, it will default to Coordinated Universal Time 'UTC'.

**download_path**: This is the directory to which files will be downloaded from iCloud. If this variable is not set, it will default to "/home/${user}/iCloud".

**synchronisation_interval**: This is the number of seconds between synchronisations. It can be set to the following periods: 21600 (6hrs), 43200 (12hrs), 86400 (24hrs), 129600 (36hrs), 172800 (48hrs) and 604800 (7 days). If this variable is not set to one of these values, it will default to 86400 seconds. Be careful if setting a short synchronisation period. Apple have a tendency to throttle connections that are hitting their server too often. I find that every 24hrs is fine. My phone will upload files to the cloud immediately, so if I lose my phone the photos I've taken that day will still be safe in the cloud, and the container will download those photos when it runs in the evening. Setting a value less than 12 hours will display a warning as Apple may throttle you.

**synchronisation_delay**: This is the number of minutes to delay the first synchronisation. This is so that you can stagger the synchronisations of multiple containers. If this value is not set. It will default to 0. It has a maximum setting of 60.

**notification_days**: When your cookie is nearing expiration, this is the number of days in advance it should notify you. This will default to 7 days if not specified so you will receive a single notification in the 7 days running up to cookie expiration.

**authentication_type**: This is the type of authentication that is enabled on your iCloud account. Valid values are '2FA' if you have two factor authentication enabled or 'Web' if you do not. If 'Web' is specified, then cookie generation is not required. If this variable is not set, it will default to '2FA'.

**directory_permissions**: This specifies the permissions to set on the directories in your download destination. If this variable is not set, it will default to 750.

**file_permissions**: This specifies the permissions to set on the files in your download destination. If this variable is not set, it will default to 640.

**folder_structure**: This specifies the folder structure to use in your download destination directory. If this variable is not set, it will set {:%Y/%m/%d} as the default. Use **none** to download to a flat file structure.

**skip_check**: This variable specifies whether the download check is skipped. If this is set to **True** the script will process a download run each time it is run. If this variable is not set, it will default to **False**.

**download_notifications**: This variable specifies whether notifications with a short summary should be sent for file downloads. If this variable is not set, it will default to **True**.

**delete_notifications**: This variable specifies whether notifications with a short summary should be sent for file deletions. If this variable is not set, it will default to **True**.

**delete_accompanying**: This variable tells the script to delete files which accompany the HEIC files that are downloaded. These are the JPG files which are created if you have HEIC to JPG conversion enabled. They are also the \_HEVC.MOV files which make up part of a live photo. This feature deletes files from your disk. I'm not responsible for any data loss.

**delete_empty_directories**: This variable tells the script to delete any empty directories it finds in the download path. It will only run if **folder_structure** isn't set to 'none'

**set_exif_datetime**: Write the DateTimeOriginal exif tag from file creation date. If this variable is not set, it will default to **False**.

**auto_delete**: Scans the "Recently Deleted" folder and deletes any files found in there. (If you restore the photo in iCloud, it will be downloaded again). If this variable is not set, it will default to **False**.

**photo_size**: Image size to download. Can be set to **original**, **medium** or **thumb**. If this variable is not set, it will default to **original**.

**skip_live_photos**: If this is set, it will skip downloading live photos. If this variable is not set, it will default to **False**.

**live_photo_size**: Live photo file size to download. Can be set to **original**, **medium** or **thumb**. If skip_live_photos is set, this setting is redundant. If this variable is not set, it will default to **original**.

**skip_videos**: If this is set, it will skip downloading videos. If this variable is not set, it will default to **False**.

**recent_only**: Set this variable to an integer number to only download this many recently added photos. If this variable is not set, it will default to downloading all photos.

**until_found**: Set this variable to an integer number to only download the most recently added photos, until *n* number of previously downloaded consecutive photos are found. If this variable is not set, it will default to downloading all photos.

**photo_album**: Set this variable to the name of an album to only download photos from this album. If this variable is not set, it will default to downloading all photos.

## OPTIONAL ENVIRONMENT VARIABLES

**command_line_options**: This is for additional command line options you want to pass to the icloudpd application. The list of options for icloudpd can be found [HERE](https://github.com/ndbroadbent/icloud_photos_downloader#usage).

**convert_heic_to_jpeg**: If this variable is set, it will convert any HEIC files it downloads to JPEG, while also retaining the original.

**jpeg_quality**: If HEIC to JPEG conversion is enabled, this variable will let you set the quality of the converted file by specifying a number from 0 (lowest quality) to 100 (highest quality) If convert_heic_to_jpeg is set, and this variable isn't, it will default to 90.

**icloud_china**: If this variable is set, it will use icloud.com.cm instead of icloud.com as the download source.

**synology_photos_app_fix**: If this variable is set, it will touch files after download to trigger the Synology Photos app to index any newly created files.

**single_pass**: If this variable is set to True, the script will exit out after a single pass instead of looping as per the synchronisation_interval. If this option is used, it will automatically disable the download check. If using this variable, the restart policy of the container must be set to "no". If it is set to "always" then the container will instantly relaunch after the first run and you will hammer Apple's website.

## NOTIFICATION CONFIGURATION VARIABLES

**notification_type**: This specifies the method that is used to send notifications. Currently, there are six options available **Prowl**, **Pushover**, **Telegram**, **Webhook**, **openhab**, **Dingtalk** and **Discord**. When the two factor authentication cookie is within 7 days (default) of expiry, a notification will be sent upon synchronisation. No more than a single notification will be sent within a 24 hour period unless the container is restarted. This does not include the notification that is sent each time the container is started.

**notification_title**: This allows you to change the title which is sent on the notifications. If this variable is not set, it will default to **boredazfcuk/iCloudPD**.

**prowl_api_key**: If the notification_type is set to 'Prowl' this is mandatory. This is the API key for your account as generated by the Prowl website.

**pushover_user**: If the notification_type is set to 'Pushover' this is mandatory. This is the Pushover user key associated with your account.

**pushover_token**: If the notification_type is set to 'Pushover' this is mandatory. This is the application API token. You will need to create an application by logging into your Pushover account and creating an application.

**pushover_sound**: If the notification_type is set to 'Pushover' this variable can be set to customise the sound of the notification. Values for this variable can be found here: https://pushover.net/api#sounds

**telegram_token**: If the notification_type is set to 'Telegram' this is mandatory. This is the token that was assigned to your account by The Botfather.

**telegram_chat_id**: If the notification_type is set to 'Telegram' then this is the chat_id for your Telegram bot. If the bot is a standard user that messages you, the chat ID will be a positive integer number. If the bot is a member of a group, and sends messages to the group, the chat ID will be prefixed with a hyphen '-' character.

**webhook_server**: If the notification_type is set to 'Webhook' or 'openhab' then this is the name of the server to connect to when sending webhook notifications.

**webhook_port**: If the notification_type is set to 'Webhook' or 'openhab' then this is the port number to use when connecting to the webhook server. If this is not set, it will default to 8123.

**webhook_path**: If the notification_type is set to 'Webhook' or 'openhab' then this is the path to use when connectiong to the webhook server. The path must start and end with a forward slash character. If this is not set, it will default to **/api/webhook/**. Openhab uses **"/rest/items/<itemname>/"**.

**webhook_id**: If the notification_type is set to 'Webhook' or 'openhab' then this is the Webhook ID to use. Openhab uses "state".

**webhook_https**: If this is set to 'True' then the Webhook or openhab notification URL will use HTTPS, otherwise it will default to HTTP.

**webhook_body**: Adapt to different services. Homeassistant uses "data" in the body of the webhook request, Discord uses "content", IFTTT uses "value1", etc.. Defaults to "data".

**dingtalk_token**: If the notification_type is set to 'Dingtalk' then this is the access token generated by the Dingtalk application. In the Dingtalk application, go to 'Security Settings', select 'Custom Keywords' and set to to the same value as **notification_title**.

**discord_id**: This is the first half of the URL generated by Discord's webhook integration.  It will be all numbers.  Do not include any /

**discord_token**: This is the second half of the URL generated by Discords webhook integration.  Do no include any /

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
   --name iCloudPD-boredazfcuk \
   --hostname icloudpd_boredazfcuk \
   --network icloudpd_bridge \
   --restart=always \
   --env user=boredazfcuk \
   --env user_id=1000 \
   --env group=admins \
   --env group_id=1010 \
   --env apple_id=thisisnotmy@email.com \
   --env apple_password="neitheristhismypassword" \
   --env authentication_type=2FA \
   --env notification_type=Telegram \
   --env telegram_token=123654 \
   --env telegram_chat_id=456321 \
   --env folder_structure={:%Y} \
   --env auto_delete=True \
   --env notification_days=14 \
   --env synchronisation_interval=21600 \
   --env TZ=Europe/London \
   --volume icloudpd_boredazfcuk_config:/config \
   --volume /home/boredazfcuk/iCloud:/home/boredazfcuk/iCloud \
   boredazfcuk/icloudpd
```

## CONFIGURING A PASSWORD

Once the container has been created, you should connect to it and run `/usr/local/bin/sync-icloud.sh --Initialise`. This will then take you through the process of adding your password to the container's keyring. It will also take you through generating a cookie that will allow the container to download the photos...

If you launch a container without initialising it first, you will receive an error message similar to this:
```
ERROR    Keyring file /config/python_keyring/keyring_pass.cfg does not exist.
INFO      - Please add the your password to the system keyring using the --Initialise script command line option.
INFO      - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise
INFO      - Example: docker exec -it icloudpd sync-icloud.sh --Initialise
INFO     Restarting in 5 minutes...
```

As per the error, the container needs to be initialised by using the --Initialise command line option. With the first container still running, connect to it and launch the initialisation process by running the following at the terminal prompt (assuming the container name is 'icloudpd'):
```
docker exec -it icloudpd sync-icloud.sh --Initialise
```

You will then be asked to log in to icloud.com, with your current Apple ID and password, and will be prompted to enter a two factor authentication code which will be sent via SMS. Once that is confirmed, the password will be added to the keyring.

If you do not have an authentication cookie, and you have two factor authentication enabled on your account, you will be taken to the cookie generation process immediately after.
   
## TWO FACTOR AUTHENTICATION

If your Apple ID account has two factor authentication enabled, you will see that the container waits for a two factor authentication cookie to be created:
```
ERROR    Cookie does not exist."
INFO      - Please create your cookie using the --Initialise script command line option."
INFO      - Syntax: docker exec -it <container name> sync-icloud.sh --Initialise"
INFO      - Example: docker exec -it icloudpd sync-icloud.sh --Initialise"
INFO     Restarting in 5 minutes..."
```

Without this cookie, synchronisation cannot be started.

As per the error, the container needs to be initialised by using the --Initialise command line option. With the first container still running, connect to it and launch the initialisation process by running the following at the terminal prompt (assuming the container name is 'icloudpd'):
```
docker exec -it icloudpd sync-icloud.sh --Initialise
```

After that, the script will log into the icloud.com website and save the 2FA cookie. Your iDevice will ask you if you want to allow or deny the login. When you allow the login, you will be give a 6-digit approval code. Enter the approval code when prompted.

The process should look similar to this:

```
2020-08-06 16:45:58 INFO     ***** boredazfcuk/icloudpd container for icloud_photo_downloader started *****
2020-08-06 16:45:58 INFO     Alpine Linux v3.12
2020-08-06 16:45:58 INFO     Interactive session: True
2020-08-06 16:45:58 INFO     Local user: user:1000
2020-08-06 16:45:58 INFO     Local group: group:1000
2020-08-06 16:45:58 INFO     LAN IP Address: 192.168.20.1
2020-08-06 16:45:58 INFO     Apple ID: email@address.com
2020-08-06 16:45:58 INFO     Authentication Type: 2FA
2020-08-06 16:45:58 INFO     Cookie path: /config/emailaddresscom
2020-08-06 16:45:58 INFO     Cookie expiry notification period: 7
2020-08-06 16:45:58 INFO     Download destination directory: /home/user/iCloud
2020-08-06 16:45:58 INFO     Folder structure: {:%Y}
2020-08-06 16:45:58 INFO     Directory permissions: 750
2020-08-06 16:45:58 INFO     File permissions: 640
2020-08-06 16:45:58 INFO     Synchronisation interval: 43200
2020-08-06 16:45:58 INFO     Time zone: Europe/London
2020-08-06 16:45:58 INFO     Additional command line options: --auto-delete --set-exif-datetime
2020-08-06 16:45:58 INFO     Correct owner on config directory, if required
2020-08-06 16:45:58 INFO     Correct group on config directory, if required
2020-08-06 16:45:58 INFO     Adding password to keyring...
Enter iCloud password for email@address.com:
Save password in keyring?  [y/N]: y
Two-step authentication required. Your trusted devices are:
  0: SMS to 07********
Which device would you like to use? [0]: 0
Please enter validation code: 123456
2020-08-06 16:47:04 INFO     Using password stored in keyring
2020-08-06 16:47:04 INFO     Correct owner on config directory, if required
2020-08-06 16:47:04 INFO     Correct group on config directory, if required
2020-08-06 16:47:04 INFO     Generate 2FA cookie with password: usekeyring
2020-08-06 16:47:04 INFO     Check for new files using password stored in keyring...
  0: SMS to 07********
  1: Enter two-factor authentication code
Please choose an option: [0]: 1
Please enter two-factor authentication code: 123456
2020-08-06 16:47:30 INFO     Two factor authentication cookie generated. Sync should now be successful.
```

This will then place a two factor authentication cookie into the /config folder of the container. This cookie will expire after three months. After it has expired, you will need to re-initialise the container again.
   
After this, the container should start downloading your photos.
   
Dockerfile has a health check which will change the status of the container to 'unhealthy' if the cookie is due to expire within a set number of days (notification_days) and also if the download fails. 

## COMMAND LINE OPTIONS

There are currently a number of command line options available to use with the sync-icloud.sh script. These are:

**--ConvertAllHEICs**
This command line option will check for HEIC files that do not have an accompanying JPEG file. If it finds a HEIC that does not have an accompaying JPEG file, it will create it. This can be used to add JPEGs for previously downloaded libraries. The easiest way to run this is to connect to the running container and executing the script.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
```
docker exec -it icloudpd sync-icloud.sh --ConvertAllHEICs
```

**--ForceConvertAllHEICs**
This command line is the same as the above option but it will overwrite any JPEG files that are already there. This will result in data loss if the downloaded JPEG files have been edited. For this reason, there is a 2 minute delay before this option runs. This gives you time to stop the container, or cancel the script, before it runs. This option is required as the heif-tools conversion utility had a bug that over-rotates the JPEG files. This means the orientation does not match the HEIC file. The heif-tools package has now been replaced by the ImageMagick package which doesn't have this problem. This command line option can be used to re-convert all your HEIC files to JPEG, overwriting the incorrectly oriented files with correctly oriented ones.

To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
```
docker exec -it icloudpd sync-icloud.sh --ForceConvertAllHEICs
```

**--ForceConvertAllmntHEICs**
This command line is the same as the above option but it will overwrite any JPEG files that it finds in the /mnt subdirectory. This will result in data loss if the downloaded JPEG files have been edited. For this reason, there is a 2 minute delay before this option runs. This gives you time to stop the container, or cancel the script, before it runs. This option is required as the heif-tools conversion utility had a bug that over-rotates the JPEG files. This means the orientation does not match the HEIC file. The heif-tools package has now been replaced by the ImageMagick package which doesn't have this problem. This command line option can be used to re-convert all your HEIC files to JPEG, overwriting the incorrectly oriented files with correctly oriented ones. This option can be used to correct JPG files that have been archived and removed from your iCloud photostream. Just mount the target directory (or directories) into the /mnt subdirectoy and the script with this command.

To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
```
docker exec -it icloudpd sync-icloud.sh --ForceConvertAllmntHEICs
```

**--CorrectJPEGTimestamps**
This command line option will correct the timestamps of JPEG files that do not match their accompanying HEIC files. Due to an omission, previous versions of my script never set the time stamp. This command line option will correct this issue.

To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
```
docker exec -it icloudpd sync-icloud.sh --CorrectJPEGTimestamps
```

**--Initialise**
This command line option will allow you to add your password to the system keyring. It will also force the creation of a new two-factor authentication cookie.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
```
docker exec -it icloudpd sync-icloud.sh --Initialise
```

## HEALTH CHECK

I have built in a health check for this container. If the script detects a download error the container will be marked as unhealthy. You can then configure this container: https://hub.docker.com/r/willfarrell/autoheal/ to monitor iCloudPD and restart the unhealthy container. Please note, if your 2FA cookie expires, the container will be marked as unhealthy, and will be restarted by the authoheal container every five minutes or so... This can lead to a lot of notifications if it happens while you're asleep!

Bitcoin: 1E8kUsm3qouXdVYvLMjLbw7rXNmN2jZesL
Litecoin: LfmogjcqJXHnvqGLTYri5M8BofqqXQttk4
