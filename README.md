# docker-icloud_photos_downloader
An Alpine Linux Docker container for ndbroadbent's icloud_photos_downloader

This dockerfile work slightly different to the official dockerfile.

It requires a fair few more variables passing to it:

USER and UID: Ideally these should match your user account on the host

GROUP and GID: Again, these should match your group information on the host

APPLEID and APPLEPASSWORD: These are needed to log in and generate an authentication token

CLIOPTIONS: (Optional) This is for additional command line options you want to pass

SETDATETIMEEXIF: (Optional) If this is true, the script will set the file's timestamp to be the same as the exif date/time (if present)

INTERVAL: This is the number of seconds between syncronisations. If not set it will default to every 24hrs.

TZ: Timezone is required by the exiftool

It also requires a named volume mapped to /config. This is where is stores the authentication cookie. Without it, it lose the cookie information each time the container is recreated.
It will download the photos to the "/home/${USERNAME}/iCloud" photos directory. You need to create a bind mount into the container at this point.

I also have a failsafe, that the launch script look for a file called .mounted in the "/home/${USERNAME}/iCloud" folder. This is so that if the disk/volume/whatever gets unmounted, sync will fail. This is to prevent it wiping iCloud if deletes are syncronised. It also prevents it from filling up the underlying root volume if the volume isn't mounted.

I create my container with the following command:

```
docker create \
   --name iCloudPD-boredazfcuk \
   --hostname icloudpd_boredafcuk \
   --network dockernetwork \
   --restart=always \
   --env USER=boredazfcuk \
   --env UID=1000 \
   --env GROUP=boredazfcuk \
   --env GID=1002 \
   --env APPLEID="boredazfcuk@emailaddress.com" \
   --env APPLEPASSWORD="Thisismypassword1" \
   --env CLIOPTIONS="--folder-structure={:%Y}" \
   --env SETDATETIMEEXIF=True \
   --env INTERVAL=21600 \
   --env TZ=Europe/London \
   --volume icloudpd_boredazfcuk_config:/config \
   --volume /this/is/the/path/to/the/host/folder:/home/boredazfcuk/iCloud \
   boredazfcuk/icloudpd
   ```
   If you launch the container after building you will receive an error as an authentication token does not exist. To create the authentication token, just run the container with the GENERATECOOKIE variable set to "True" and point it to the same named /config volume:
   ```
   docker run -it --rm \
   --name iCloudPD-boredazfcuk-2FA \
   --hostname icloudpd_boredazfcuk_2fa \
   --network containers \
   --env USER=boredazfcuk \
   --env UID=1000 \
   --env GROUP=boredazfcuk \
   --env GID=1001 \
   --env APPLEID="boredazfcuk@emailaddress.com" \
   --env APPLEPASSWORD="Thisismypassword1" \
   --env GENERATECOOKIE="True" \
   --volume icloudpd_boredazfcuk_config:/config \
   boredazfcuk/icloudpd
   ```
   After this, the iCloudPD-boredazfcuk container should launch and the startup script will loop after every INTERVAL
