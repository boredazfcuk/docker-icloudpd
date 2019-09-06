# docker-icloud_photos_downloader
An Alpine Linux Docker container for ndbroadbent's icloud_photos_downloader

This dockerfile work slightly different to the official dockerfile.

## MANDATORY ENVIRONMENT VARIABLES

USER: This is name of the user account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user on the host system for which you want to download files for. This user will be set as the owner of all downloaded files.

UID: This is the User ID number of the above user account. This can be any number that isn't already in use. Ideally, you should set this to be the same ID number as the USER's ID on the host system. This will avoid permissions issues if syncing to your host's home directory.

GROUP: This is name of the group account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user's primary group on the host system. This This group will be set as the group for all downloaded files.

GID: This is the Group ID number of the above group. This can be any number that isn't already in use. Ideally, you should set this to be the same Group ID number as the user's primary group on the host system.

APPLEID: This is the Apple ID for the account you want to download files for.

APPLEPASSWORD: This is the password for the Apple ID account named above. This is needed to generate an authentication token.

TZ: This is the local timezone and is required by the exiftool to calculate local time from the timestamps.

## OPTIONAL ENVIRONMENT VARIABLES

CLIOPTIONS: This is for additional command line options you want to pass to the icloudpd application. The list of options for icloudpd can be found [HERE](https://github.com/ndbroadbent/icloud_photos_downloader#usage)

SETDATETIMEEXIF: This option sets the downloaded file's time stamp to be the same as the time stored within the file's exif data.

INTERVAL: This is the number of seconds between syncronisations. Common intervals would be: 3hrs - 10800, 4hrs - 14400, 6hrs - 21600 & 12hrs - 43200. If variable is not set it will default to every 24hrs (86400 seconds).

## VOLUME CONFIGURATION

It also requires a named volume mapped to /config. This is where is stores the authentication cookie. Without it, it lose the cookie information each time the container is recreated.
It will download the photos to the "/home/${USERNAME}/iCloud" photos directory. You need to create a bind mount into the container at this point.

I also have a failsafe built in. The launch script will look for a file called .mounted in the "/home/${USERNAME}/iCloud" folder. If this file is not present, it will not sync with iCloud. This is so that if the underlying disk/volume/whatever gets unmounted, sync will not occur. This prevents the script from filling up the root volume if the underlying volume isn't mounted for whatever reason. This file **MUST** be created manually and sync will not start without it.

## CREATING A CONTAINER

To create a container, run the following command from a shell on the host, filling in the details as per your requirements:

```
docker create \
   --name <Contrainer Name> \
   --hostname <Hostname of container> \
   --network <Name of Docker network to connect to> \
   --restart=always \
   --env USER=<User Name> \
   --env UID=<User ID> \
   --env GROUP=<Group Name> \
   --env GID=<Group ID> \
   --env APPLEID="<Apple ID e-mail address>" \
   --env APPLEPASSWORD="Apple ID password" \
   --env CLIOPTIONS="<Any additional commands you wish to pass to icloudpd" \
   --env SETDATETIMEEXIF=<If required set to "True", otherwise omit this option> \
   --env INTERVAL=<Include this if you wish to override the default interval of 24hrs> \
   --env TZ=<The local time zone> \
   --volume <Named volume which is mapped to /config> \
   --volume <Bind mount to the destination folder on the host> \
   <image name>
   ```
   
   This is an example of the command I run to create a container on my own machine:
   
   ```
   docker create \
   --name iCloudPD-boredazfcuk \
   --hostname icloudpd_boredazfcuk \
   --network containers \
   --restart=always \
   --env USER=boredazfcuk \
   --env UID=1000 \
   --env GROUP=admins \
   --env GID=1010 \
   --env APPLEID="thisisnotmy@email.com" \
   --env APPLEPASSWORD="neitheristhismypassword" \
   --env CLIOPTIONS="--folder-structure={:%Y} --recent 50" \
   --env SETDATETIMEEXIF=True \
   --env INTERVAL=21600 \
   --env TZ=Europe/London \
   --volume icloudpd_boredazfcuk_config:/config \
   --volume /home/boredazfcuk/iCloud:/home/boredazfcuk/iCloud \
   boredazfcuk/icloudpd
   ```
   
After creating the container. It will need to be initialised with an authentication token. This must be done by running a second container momentarily from a shell prompt on the host. The second container will log in to your Apple ID account and generate an authentication cookie. This will be stored in the /config folder in the container and will expire after two months. After it has expired, you will need to re-initialise the container again. If you have 2FA authentication enabled on your Apple account, you will be prompted on your iDevice to allow or deny the login. You will need to allow the login and then you will be presented with a 6 digit code. Enter this code into the shell prompt when required. After this containter has run, it will automatically remove itself.

## CREATING AN AUTHENTICATION TOKEN
   
To create the authentication token, just run the container with the GENERATECOOKIE variable set to "True" and point it to the same named /config volume:
   ```
   docker run -it --rm \
   --network <Same as the previously created contrainer> \
   --env USER=<Same as the previously created contrainer> \
   --env UID=<Same as the previously created contrainer> \
   --env GROUP=<Same as the previously created contrainer> \
   --env GID=<Same as the previously created contrainer> \
   --env APPLEID="<Same as the previously created contrainer>" \
   --env APPLEPASSWORD="<Same as the previously created contrainer>" \
   --env GENERATECOOKIE="True" \
   --volume <Same named volume as the previously created contrainer> \
   <Name of the image you created>
   ```
   
This is an example of the command I run to create the authentication token on my own machine:
```
docker run -it --rm \
   --network containers \
   --env USER=boredazfcuk \
   --env UID=1000 \
   --env GROUP=admins \
   --env GID=1010 \
   --env APPLEID="thisisnotmy@email.com" \
   --env APPLEPASSWORD="neitheristhismypassword" \
   --env GENERATECOOKIE="True" \
   --volume icloudpd_james_config:/config \
   boredazfcuk/icloudpd
```

After this, my iCloudPD-boredazfcuk container launchs and the startup script loops after every interval.
   
Dockerfile now has a health check which will change the status of the container to 'unhealthy' if the cookie is due to expire within 7 days.
   
# TO DO
      Configure notifications
