#!/bin/bash
# Configure these values:
UID=
GID=
VOL_COOKIE=
VOL_DATA=
CLIOPTIONS=

docker pull bitprocessor/icloudpd:latest
docker run -d \
   --name icloudpd_maarten \
   --restart=always \
   --user ${UID}:${GID} \
   --env APPLEID="email@example.com" \
   --env APPLEPASSWORD="secret" \
   --env SETDATETIMEEXIF="True" \
   --env CLIOPTIONS="$CLIOPTIONS" \
   --volume ${VOL_COOKIE}:/cookie \
   --volume ${VOL_DATA}:/data \
   bitprocessor/icloudpd:latest
