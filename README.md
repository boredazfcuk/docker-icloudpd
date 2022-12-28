# docker-icloudpd
An Alpine Linux Docker container for ndbroadbent's iCloud Photos Downloader. I use it for syncing the photo streams of all the iDevices in my house back to my server because it's the only way of backing up multiple devices to a single location. It uses the system keyring to securely store credentials, has HEIC to JPG conversion capability, and can send Telegram, Prowl, Pushover, WebHook, DingTalk, Discord, openhab, IYUU and WeCom notifications.

## MANDATORY ENVIRONMENT VARIABLES
**apple_id**: This is the Apple ID that will be used when downloading files.

## DEFAULT ENVIRONMENT VARIABLES

**user**: This is name of the user account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user on the host system for which you want to download files for. This user will be set as the owner of all downloaded files. This variable will default to 'user'.

**user_id**: This is the User ID number of the above user account. This can be any number that isn't already in use. Ideally, you should set this to be the same ID number as the user's ID on the host system. This will avoid permissions issues if syncing to your host's home directory. This variable will default to '1000'.

**group**: This is name of the group account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user's primary group on the host system. This This group will be set as the group for all downloaded files. This variable will default to 'group'.

**group_id**: This is the Group ID number of the above group. This can be any number that isn't already in use. Ideally, you should set this to be the same Group ID number as the user's primary group on the host system. This variable will default to '1000'.

**force_gid**: If this variable is set it will allow the group to be created with a pre-existing group id. This may be handy if your group id clashes with a system group insude the docker container, however, if may have undesired permissions issues. Please use with caution.

**TZ**: Sets the local timezone and is required to calculate timestamps. This variable will default to Coordinated Universal Time 'UTC'.

**download_path**: This is the directory to which files will be downloaded from iCloud. This variable will default to "/home/${user}/iCloud".

**synchronisation_interval**: This is the number of seconds between synchronisations. It can be set to the following periods: 21600 (6hrs), 43200 (12hrs), 86400 (24hrs), 129600 (36hrs), 172800 (48hrs) and 604800 (7 days). If this variable is not set to one of these values, it will default to 86400 seconds. Be careful if setting a short synchronisation period. Apple have a tendency to throttle connections that are hitting their server too often. I find that every 24hrs is fine. My phone will upload files to the cloud immediately, so if I lose my phone the photos I've taken that day will still be safe in the cloud, and the container will download those photos when it runs in the evening. Setting a value less than 12 hours will display a warning as Apple may throttle you.

**synchronisation_delay**: This is the number of minutes to delay the first synchronisation. This is so that you can stagger the synchronisations of multiple containers. If this value is not set. It will default to 0. It has a maximum setting of 60.

**notification_days**: When your cookie is nearing expiration, this is the number of days in advance it should notify you. This will default to 7 days if not specified. You will receive a single notification, per day, in the days running up to cookie expiration.

**authentication_type**: This is the type of authentication that is enabled on your iCloud account. Valid values are '2FA' if you have two factor authentication enabled or 'Web' if you do not. If 'Web' is specified, then cookie generation is not required. This variable will default to '2FA'.

**directory_permissions**: This specifies the permissions to set on the directories in your download destination. This variable will default to 750.

**file_permissions**: This specifies the permissions to set on the files in your download destination. This variable will default to 640.

**folder_structure**: This specifies the folder structure to use in your download destination directory. If this variable is not set, it will set {:%Y/%m/%d} as the default. Use **none** to download to a flat file structure. Use  **album** to store in folders with same name as on iCloud.com

**skip_check**: Set this to **True** skip the check for new files. The check can have issues with large libraries, please set to **True** if you have more than a few thousand photos. This variable will default to **False**.

**download_notifications**: specifies whether notifications with a short summary should be sent for file downloads. This variable will default to **True**.

**delete_notifications**: Specifies whether notifications with a short summary should be sent for file deletions. This variable will default to **True**.

**delete_accompanying**: Tells the script to delete files which accompany the HEIC files that are downloaded. These are the JPG files which are created if you have HEIC to JPG conversion enabled. They are also the \_HEVC.MOV files which make up part of a live photo. This feature deletes files from your disk. I'm not responsible for any data loss.

**delete_empty_directories**: Tells the script to delete any empty directories it finds in the download path. It will only run if **folder_structure** isn't set to 'none'

**set_exif_datetime**: Write the DateTimeOriginal exif tag from file creation date. This variable will default to **False**.

**auto_delete**: Scans the "Recently Deleted" folder and deletes any files found in there. (If you restore the photo in iCloud, it will be downloaded again). This variable will default to **False**.

**photo_size**: Image size to download. Can be set to **original**, **medium** or **thumb**. This variable will default to **original**.

**skip_live_photos**: If this is set, it will skip downloading live photos. This variable will default to **False**.

**live_photo_size**: Live photo file size to download. Can be set to **original**, **medium** or **thumb**. If skip_live_photos is set, this setting is redundant. This variable will default to **original**.

**skip_videos**: If this is set, it will skip downloading videos. This variable will default to **False**.

**recent_only**: Set this to an integer number to only download this many recently added photos. This variable will default to downloading all photos.

**until_found**: Set this to an integer number to only download the most recently added photos, until *n* number of previously downloaded consecutive photos are found. This variable will default to downloading all photos.

**photo_album**: Set this to the name of an album to only download photos from a single album.

**photo_library**: Set this to the name of an iOS 16 shared library to only download photos from a single shared library. Please note, due to issues with the shared libraries patch it has been moved to a different container. Please pull boredazfcuk/icloudpd:testing for this version of the container.

## OPTIONAL ENVIRONMENT VARIABLES

**command_line_options**: This is for additional command line options you want to pass to the icloudpd application. The list of options for icloudpd can be found [HERE](https://github.com/ndbroadbent/icloud_photos_downloader#usage).

**convert_heic_to_jpeg**: Set this to True to convert downloaded HEIC files to JPEG, while also retaining the original.

**jpeg_path**: Set this variable to specify a different location for the converted JPEGs. This variable will default to "/home/${user}/iCloud", or **download_path** if not set, thereby placing the JPEG files alongside the HEIC files.

**jpeg_quality**: If HEIC to JPEG conversion is enabled, this variable will let you set the quality of the converted file by specifying a number from 0 (lowest quality) to 100 (highest quality) If convert_heic_to_jpeg is set, and this variable isn't, it will default to 90.

**icloud_china**: Set this to True to use icloud.com.cm instead of icloud.com as the download source.

**synology_photos_app_fix**: Set this to True to touch files after download and trigger the Synology Photos app to index any newly created files.

**single_pass**: Set this to True to exit out after a single pass instead of looping as per the synchronisation_interval. If this option is used, it will automatically disable the download check. If using this variable, the restart policy of the container must be set to "no". If it is set to "always" then the container will instantly relaunch after the first run and you will hammer Apple's website.

**trigger_nextlcoudcli_synchronisation**: This creates a file in the download directory after a new files are downloaded. My NextcloudCLI container will detect this and force an immediate sync to the Nextcloud server.

## NOTIFICATION CONFIGURATION VARIABLES

The README on Dockerhub has a hard limit of 25,000 characters, and I'd hit this limit multiple times. I'd changed the wording of this README.md file time and time again to keep it under that limit, but I've finally conceeded and just moved this section to it's own file. Please see NOTIFICATIONS.md for further details. It is available here: https://github.com/boredazfcuk/docker-icloudpd/blob/master/NOTIFICATIONS.md

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
   --env user=boredazfcuk \
   --env user_id=1000 \
   --env group=admins \
   --env group_id=1010 \
   --env apple_id=notmy@email.com \
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

Note: Raspberry Pi users have reported that the container only functions correctly when the containes is created with the `--privileged` parameter.

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
`docker exec -it icloudpd sync-icloud.sh --Initialise`

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
2020-08-06 16:45:58 INFO     Adding password to keyring...
Enter iCloud password for email@address.com:
Save password in keyring?  [y/N]: y
Two-step authentication required. Your trusted devices are:
  0: SMS to 07********
Which device would you like to use? [0]: 0
Please enter validation code: 123456
2020-08-06 16:47:04 INFO     Using password stored in keyring
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
`docker exec -it icloudpd sync-icloud.sh --ConvertAllHEICs`

**--ForceConvertAllHEICs**
This command line is the same as the above option but it will overwrite any JPEG files that are already there. This will result in data loss if the downloaded JPEG files have been edited. For this reason, there is a 2 minute delay before this option runs. This gives you time to stop the container, or cancel the script, before it runs. This option is required as the heif-tools conversion utility had a bug that over-rotates the JPEG files. This means the orientation does not match the HEIC file. The heif-tools package has now been replaced by the ImageMagick package which doesn't have this problem. This command line option can be used to re-convert all your HEIC files to JPEG, overwriting the incorrectly oriented files with correctly oriented ones.

To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --ForceConvertAllHEICs`

**--ForceConvertAllmntHEICs**
This command line is the same as the above option but it will overwrite any JPEG files that it finds in the /mnt subdirectory. This will result in data loss if the downloaded JPEG files have been edited. For this reason, there is a 2 minute delay before this option runs. This gives you time to stop the container, or cancel the script, before it runs. This option is required as the heif-tools conversion utility had a bug that over-rotates the JPEG files. This means the orientation does not match the HEIC file. The heif-tools package has now been replaced by the ImageMagick package which doesn't have this problem. This command line option can be used to re-convert all your HEIC files to JPEG, overwriting the incorrectly oriented files with correctly oriented ones. This option can be used to correct JPG files that have been archived and removed from your iCloud photostream. Just mount the target directory (or directories) into the /mnt subdirectoy and the script with this command.

To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --ForceConvertAllmntHEICs`

**--CorrectJPEGTimestamps**
This command line option will correct the timestamps of JPEG files that do not match their accompanying HEIC files. Due to an omission, previous versions of my script never set the time stamp. This command line option will correct this issue.

To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --CorrectJPEGTimestamps`

**--Initialise**
This command line option will allow you to add your password to the system keyring. It will also force the creation of a new two-factor authentication cookie.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --Initialise`

**--RemoveKeyring**
This command line option will delete the system keyring file. You will need to run this if you change your Apple ID password.
To run the script inside the currently running container, issue this command (assuming the container name is 'icloudpd'):
`docker exec -it icloudpd sync-icloud.sh --RemoveKeyring`

## HEALTH CHECK

I have built in a health check for this container. If the script detects a download error the container will be marked as unhealthy. You can then configure this container: https://hub.docker.com/r/willfarrell/autoheal/ to monitor iCloudPD and restart the unhealthy container. Please note, if your 2FA cookie expires, the container will be marked as unhealthy, and will be restarted by the authoheal container every five minutes or so... This can lead to a lot of notifications if it happens while you're asleep!

## TROUBLESHOOTING

The app which runs inside this container connects to iCloud.com website and downloads the files it finds in there. Basically the same way as you would if you were downloading the files in your web browser, as Apple does not provide the capability to do this via an API (gotta love Apple's walled-garden). This is problematic because if the website changes at all, it throws the downloader out due to the website is doing something unexpected. There are many reasons that the website can change, for example, if somebody attempts to brute-force your account, you will be prompted to confirm your security questions the next time you log in. Accounts without two-factor authentication enabled will periodically receive a prompt upon login about upgrading the account's security.

If you have enabled Apple's Advanced Data Protection feature in iOS 16.2, you will need to disable it. This feature encrypts your photos on icloud.com and means it can only be accessed from your trusted devices, as Apple no longer stores your encryption keys on their servers. I presume that the Photos section of icloud.com will no longer allow you to view photos with the Advanced Data Protection option enabled.

If your container starts erroring out all of a sudden, the first thing to do is to log into iCloud.com and check that there isn't some pop-up notification which needs clearing. If that doens't work, then try re-initialising your container. For larger libraries with thousands of images, disabling the download check is also a requirement, so please try that.

Bitcoin: 1E8kUsm3qouXdVYvLMjLbw7rXNmN2jZesL
Litecoin: LfmogjcqJXHnvqGLTYri5M8BofqqXQttk4
