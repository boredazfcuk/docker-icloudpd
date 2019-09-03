#!/bin/ash

COOKIE="${APPLEID//_/}"
COOKIE="${COOKIE// /_}"
COOKIE="${COOKIE//[^a-zA-Z0-9_]/}"
COOKIE="$(echo -n "${COOKIE}" | tr A-Z a-z)"

CheckCookie(){
   if [ "$(find "${CONFIGDIR}" -type f -name "${COOKIE}" -mtime +55 | wc -l)" -ne 0 ]; then
      find "${CONFIGDIR}" -type f -name "${COOKIE}" -mtime +55 -delete
   fi
   while [ ! -f "${CONFIGDIR}/${COOKIE}" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie does not exist. Container must be run interactively to generate an authentication cookie - retry in 5 minutes"
      sleep 300
   done
}

CreateGroup(){
   if [ -z "$(getent group ${GROUP} | cut -d: -f3)" ]; then
      addgroup -g "${GID}" "${GROUP}"
   elif [ ! "$(getent group "${GROUP}" | cut -d: -f3)" = "${GID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Group GID mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${USER}" | cut -d: -f3)" ]; then
      adduser -s /bin/ash -D -G "${GROUP}" -u "${UID}" "${USER}" -h "/home/$USER"
   elif [ ! "$(getent passwd "${USER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User UID mismatch - exiting"
      exit 1
   fi
}

if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User name invalid - exiting" && exit 1; fi
if [ -z "${APPLEID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID invalid - exiting" && exit 1; fi
if [ -z "${APPLEPASSWORD}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple Password not specified - exiting" && exit 1; fi
if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Group name invalid - exiting" && exit 1; fi
if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Group ID invalid - exiting" && exit 1; fi
if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User name invalid - exiting" && exit 1; fi
if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User ID invalid - exiting" && exit 1; fi

if [ "${GENERATECOOKIE}" = "True" ]; then
   CreateGroup
   CreateUser
   su "${USER}" -c "/usr/bin/icloudpd --username \"${APPLEID}\" --password=\"${APPLEPASSWORD}\" --cookie-directory=\"${CONFIGDIR}\""
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie generated. Sync should now be successful"
   exit 0
fi

CheckCookie

if [ ! -f "/home/${USER}/iCloud/.mounted" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     iCloud folder not mounted - exiting" && exit 1; fi
if [ -z "${INTERVAL}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sync interval not specified - exiting" && exit 1; fi

echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local account: ${USER}-${UID}:${GROUP}-${GID}"
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple account: ${APPLEID}:${APPLEPASSWORD}"
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie directory: ${CONFIGDIR}"
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     iCloud directory: /home/${USER}/iCloud"
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Command line options: ${CLIOPTIONS}"

CreateGroup
CreateUser

if [ "$(find "/home/${USER}/iCloud" ! -user "${USER}" |wc -l)" -ne 0 ]; then
   find "/home/${USER}/iCloud" ! -user "${USER}" -exec chown "${USER}" {} \;
fi
if [ "$(find "/home/${USER}/iCloud" ! -group "${GROUP}" | wc -l)" -ne 0 ]; then
   find "/home/${USER}/iCloud" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
fi

while :; do
   CheckCookie
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation for ${USER} started"
   if [ -f "/home/${USER}/iCloud/.mounted" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sync ${USER} iCloud..."
      su -s /bin/ash "${USER}" -c "/usr/bin/icloudpd --directory \"/home/${USER}/iCloud\" --cookie-directory=\"${CONFIGDIR}\" --username=\"${APPLEID}\" --password=\"${APPLEPASSWORD}\" \""${CLIOPTIONS}"\""
      if [ $? -ne 0 ]; then "$(date '+%Y-%m-%d %H:%M:%S') INFO     Exit code non-zero - Error: $?"; fi
      if [ "${SETDATETIMEEXIF}" = "True" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set correct file time stamp from exif data..."
         exiftool -d "%Y:%m:%d %H:%M:%S" '-FileModifyDate<createdate' '-FileModifyDate<creationdate' '-filemodifydate<datetimeoriginal' -if '(($datetimeoriginal and ($datetimeoriginal ne $filemodifydate)) or ($creationdate and ($creationdate ne $filemodifydate)))' -r -q "/home/${USER}/iCloud"
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set group and permissions of downloaded files..."
      if [ "$(find "/home/${USER}/iCloud" -type d ! -group "${GROUP}" | wc -l )" -ne 0 ]; then 
         find "/home/${USER}/iCloud" -type d ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
      fi
      if [ "$(find "/home/${USER}/iCloud" -type f ! -group "${GROUP}" | wc -l )" -ne 0 ]; then
         find "/home/${USER}/iCloud" -type f ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
      fi
      if [ "$(find "/home/${USER}/iCloud" -type d ! -perm 770 | wc -l )" -ne 0 ]; then
         find "/home/${USER}/iCloud" -type d ! -perm 770 -exec chmod 770 {} +
      fi
      if [ "$(find "/home/${USER}/iCloud" -type f ! -perm 660 | wc -l)" -ne 0 ]; then
         find "/home/${USER}/iCloud" -type f ! -perm 660 -exec chmod 660 {} +
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation for ${USER} complete"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Next syncronisation at $(date +%H:%M -d "${INTERVAL} seconds")"
      sleep "${INTERVAL}"
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Underlying volume is not mounted. Waiting a minute before retrying"
      sleep 60
   fi
done