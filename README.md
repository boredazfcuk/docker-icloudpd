# iCloudPD-docker
An Alpine based Docker image for ndbroadbent's iCloud Photos Downloader
Docker Hub: https://hub.docker.com/r/bitprocessor/icloudpd

## MANDATORY ENVIRONMENT VARIABLES

APPLEID: This is the Apple ID for the account you want to download files for.

APPLEPASSWORD: This is the password for the Apple ID account named above. This is needed to generate an authentication token.

## DEFAULT ENVIRONMENT VARIABLES

TZ: This is the local timezone and is required by the exiftool to calculate local time from the timestamps. If this variable is not set, it will default to Europe/Stockholm

INTERVAL: This is the number of seconds between syncronisations. Common intervals would be: 3hrs - 10800, 4hrs - 14400, 6hrs - 21600 & 12hrs - 43200. If variable is not set it will default to every 24hrs (86400 seconds).

NOTIFICATIONDAYS: This is number of days until cookie expiration for which to generate notifications. This will default to 7 days if not specified so you will receive a single notification in the 7 days running up to cookie expiration.

AUTHTYPE: This is the type of authentication that is enabled on your iCloud account. Valid values are '2FA' if you have two factor authentication enabled or 'Web' if you do not. If 'Web' is specified, then cookie generation is not required. If this variable is not set, it will default to '2FA'

## OPTIONAL ENVIRONMENT VARIABLES

CLIOPTIONS: This is for additional command line options you want to pass to the icloudpd application. The list of options for icloudpd can be found [HERE](https://github.com/bitprocessor/icloudpd-docker#usage)

SETDATETIMEEXIF: This option sets the downloaded file's time stamp to be the same as the time stored within the file's exif data.

## VOLUME CONFIGURATION

* /config: stores the authentication cookie

* /data: stores the downloaded data

Both folders need to be mapped to an existing folder.


## TWO FACTOR AUTHENTICATION

If your Apple ID account has two factor authentication enabled, start by running the container in interactive terminal mode.
