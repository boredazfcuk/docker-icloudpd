#!/bin/bash
# Configure these values:
UID=
GID=
VOL_COOKIE=
VOL_DATA=

docker pull bitprocessor/icloudpd:latest
docker run -it --rm \
   --user ${UID}:${GID} \
   --env APPLEID="email@example.com" \
   --env APPLEPASSWORD="secret" \
   --volume ${VOL_COOKIE}:/cookie \
   --volume ${VOL_DATA}:/data \
   bitprocessor/icloudpd:latest
