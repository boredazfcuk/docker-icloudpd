#!/bin/ash

##### Functions #####
CheckTerminal(){
   if [ -t 0 ]; then
      INTERACTIVE=True
   else
      INTERACTIVE=False
   fi
}

CookieName(){
   COOKIE="${APPLEID//_/}"
   COOKIE="${COOKIE// /_}"
   COOKIE="${COOKIE//[^a-zA-Z0-9_]/}"
   COOKIE="$(echo -n "${COOKIE}" | tr A-Z a-z)"
}

CheckCookie(){
   if [ $(grep -c -e "X-APPLE-WEBAUTH-HSA-TRUST" "${CONFIGDIR}/${COOKIE}") -eq 1 ]; then
      AUTHTYPE="2FA"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Authentication type not set, but two factor authentication cookie exists. Changing to 2FA"
   else
      AUTHTYPE="Web"
   fi
}

Check2FAExpiration(){
   EXPIRE2FA="$(grep "X-APPLE-WEBAUTH-HSA-TRUST" "${CONFIGDIR}/${COOKIE}" | sed -e 's#.*expires="\(.*\)"; HttpOnly.*#\1#')"
   EXPIRE2FA="${EXPIRE2FA::-1}"
   EXPIRE2FASECS="$(date -d "${EXPIRE2FA}" '+%s')"
   DAYSREMAINING="$(($((EXPIRE2FASECS - $(date '+%s'))) / 86400))"
   while [ "${DAYSREMAINING}" -lt 1 ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie has expired. Container must be run interactively to generate an authentication cookie - retry in 5 minutes"
      sleep 300
   done
}

Generate2FACookie(){
   if [ -f "${CONFIGDIR}/${COOKIE}" ]; then
      rm "${CONFIGDIR}/${COOKIE}"
   fi
   su "${USER}" -c "/usr/bin/icloudpd --username \"${APPLEID}\" --password \"${APPLEPASSWORD}\" --cookie-directory \"${CONFIGDIR}\""
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie generated. Sync should now be successful"
   exit 0
}

CreateGroup(){
   if [ -z "$(getent group ${GROUP} | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Group ID available, creating group"
      addgroup -g "${GID}" "${GROUP}"
   elif [ ! "$(getent group "${GROUP}" | cut -d: -f3)" = "${GID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group ID already in use - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${USER}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     User ID available, creating user"
      adduser -s /bin/ash -D -G "${GROUP}" -u "${UID}" "${USER}" -h "/home/$USER"
   elif [ ! "$(getent passwd "${USER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User ID already in use - exiting"
      exit 1
   fi
}

CheckVariables(){
   if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  User name not set, defaulting to 'user'"; USER="user"; fi
   if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  User ID not set, defaulting to '1000'"; UID="1000"; fi
   if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Group name not set, defaulting to 'group'"; GROUP="group"; fi
   if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Group ID not set, defaulting to '1000'"; GID="1000"; fi
   if [ -z "${INTERVAL}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Syncronisation interval not set, defaulting to 1 day"; INTERVAL="86400"; fi
   if [ -z "${TZ}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Time zone not set, defaulting to Coordinated Universal Time 'UTC'"; export TZ="UTC"; fi
   if [ -z "${AUTHTYPE}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Authentication type not set, defaulting to two factor authentication"; AUTHTYPE="2FA"; fi
   if [ "${NOTIFICATIONTYPE}" = "Prowl" ] && [ -z "${PROWLAPIKEY}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Prowl notifications enabled, but Prowl API key not set - disabling notifications"
      unset "${NOTIFICATIONTYPE}"
   elif [ "${NOTIFICATIONTYPE}" = "Prowl" ] && [ ! -z "${PROWLAPIKEY}" ]; then
         NEXTNOTIFICATION="$(date +%s)"
   fi
   if [ -z "${APPLEPASSWORD}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID Password not set - exiting"; exit 1; fi
   if [ -z "${APPLEID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID not set - exiting"; exit 1; fi
}

CheckMount(){
   while [ ! -f "/home/${USER}/iCloud/.mounted" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Destination volume not mounted - retry in 5 minutes"
      sleep 300
   done
}

DisplayVariables(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local user: ${USER}:${UID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Local group: ${GROUP}:${GID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID: ${APPLEID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID Password: ${APPLEPASSWORD}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie directory: ${CONFIGDIR}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     iCloud directory: /home/${USER}/iCloud"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Command line options: ${CLIOPTIONS}"
}

SetOwnerAndGroup(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set group and permissions of downloaded files..."
   if [ "$(find "/home/${USER}/iCloud" ! -user "${USER}" | wc -l)" -ne 0 ]; then
      find "/home/${USER}/iCloud" ! -user "${USER}" -exec chown "${USER}" {} \;
   fi
   if [ "$(find "/home/${USER}/iCloud" ! -group "${GROUP}" | wc -l )" -ne 0 ]; then 
      find "/home/${USER}/iCloud" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   fi
   if [ "$(find "/home/${USER}/iCloud" -type d ! -perm 770 | wc -l )" -ne 0 ]; then
      find "/home/${USER}/iCloud" -type d ! -perm 770 -exec chmod 770 {} +
   fi
   if [ "$(find "/home/${USER}/iCloud" -type f ! -perm 660 | wc -l)" -ne 0 ]; then
      find "/home/${USER}/iCloud" -type f ! -perm 660 -exec chmod 660 {} +
   fi
}

SetDateTimeFromExif(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set correct file time stamp from exif data..."
   exiftool -d "%Y:%m:%d %H:%M:%S" '-FileModifyDate<createdate' '-FileModifyDate<creationdate' '-filemodifydate<datetimeoriginal' -if '(($datetimeoriginal and ($datetimeoriginal ne $filemodifydate)) or ($creationdate and ($creationdate ne $filemodifydate)))' -r -q "/home/${USER}/iCloud"
}

NotifyProwl(){
   curl https://api.prowlapp.com/publicapi/add \
      -F apikey="${PROWLAPIKEY}" \
      -F application="$(date)" \
      -F event="iCloud Photo Downloader" \
      -F priority="${1}" \
      -F description="${2}" \
      >/dev/null 2>&1 &
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Prowl notification sent - ${2}"
   NEXTNOTIFICATION=$(date +%s -d "+24 hour")
}

##### Script #####
CheckTerminal
CookieName
CheckVariables
CreateGroup
CreateUser
if [ -z "${AUTHTYPE}" ] && [ -f "${CONFIGDIR}/${COOKIE}" ]; then CheckCookie; fi
DisplayVariables
if [ "${AUTHTYPE}" = "2FA" ] && [ ! -f "${CONFIGDIR}/${COOKIE}" ] && [ "${INTERACTIVE}" = "False" ]; then
   echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Two factor authentication enabled, but cookie does not exist"
   while [ ! -f "${CONFIGDIR}/${COOKIE}" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Please generate cookie using an interactive session - retry in 5 minutes"
      sleep 300
   done
elif [ "${AUTHTYPE}" = "2FA" ] && [ ! -f "${CONFIGDIR}/${COOKIE}" ] && [ "${INTERACTIVE}" = "True" ]; then
   Generate2FACookie
fi
if [ "${AUTHTYPE}" = "2FA" ]; then Check2FAExpiration; fi
CheckMount
SetOwnerAndGroup

while :; do
   if [ "${AUTHTYPE}" = "2FA" ]; then Check2FAExpiration; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation started for ${USER}"
   SYNCTIME="$(date +%s -d '+15 minutes')"
   CheckMount
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sync ${USER} iCloud..."
   su -s /bin/ash "${USER}" -c "/usr/bin/icloudpd --directory /home/${USER}/iCloud --cookie-directory \"${CONFIGDIR}\" --username \"${APPLEID}\" --password \"${APPLEPASSWORD}\" \""${CLIOPTIONS}"\""
   if [ $? -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Exit code non-zero - Error: $?"
   fi
   if [ "${SETDATETIMEEXIF}" = "True" ]; then
      SetDateTimeFromExif
   fi
   SetOwnerAndGroup
   if [ "${AUTHTYPE}" = "2FA" ]; then 
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie expires: ${EXPIRE2FA/ / @ }"
      if [ "${DAYSREMAINING}" -lt 7 ]; then
         if [ "${SYNCTIME}" -gt "${NEXTNOTIFICATION}" ]; then
            if [ "${DAYSREMAINING}" -eq 1 ]; then
               echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Final day before two factor authentication cookie expires - Please reinitialise now"
               if [ "${NOTIFICATIONTYPE}" = "Prowl" ]; then
                  NotifyProwl "2" "Final day before two factor authentication cookie expires - Please reinitialise now"
               fi
            else
               echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Only ${DAYSREMAINING} days until two factor authentication cookie expires - Please reinitialise"
               if [ "${NOTIFICATIONTYPE}" = "Prowl" ]; then
                  NotifyProwl "1" "Only ${DAYSREMAINING} days until two factor authentication cookie expires - Please reinitialise"
               fi
            fi
         fi
      fi
   fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation complete for ${USER}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Next syncronisation at $(date +%H:%M -d "${INTERVAL} seconds")"
   sleep "${INTERVAL}"
done
