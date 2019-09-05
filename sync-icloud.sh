#!/bin/ash

COOKIE="${APPLEID//_/}"
COOKIE="${COOKIE// /_}"
COOKIE="${COOKIE//[^a-zA-Z0-9_]/}"
COOKIE="$(echo -n "${COOKIE}" | tr A-Z a-z)"

CheckCookie(){
   if [ -f "${CONFIGDIR}/${COOKIE}" ]; then
      if [ "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "${CONFIGDIR}/${COOKIE}")" -eq 1 ]; then
         EXPIRE2FA="$(cat "${CONFIGDIR}/${COOKIE}" | grep "X-APPLE-WEBAUTH-HSA-TRUST" | sed -e 's#.*expires="\(.*\)"; HttpOnly.*#\1#')"
         EXPIREWEB="$(cat "${CONFIGDIR}/${COOKIE}" | grep "X_APPLE_WEB_KB" | sed -e 's#.*expires="\(.*\)"; HttpOnly.*#\1#')"
      else
         while [ ! "$(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "${CONFIGDIR}/${COOKIE}")" -eq 1 ]; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie has expired. Container must be run interactively to generate an authentication cookie - retry in 5 minutes"
            sleep 300
         done
      fi
   fi
   while [ ! -f "${CONFIGDIR}/${COOKIE}" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie does not exist. Container must be run interactively to generate an authentication cookie - retry in 5 minutes"
      sleep 300
   done
}

CreateGroup(){
   if [ -z "$(getent group ${GROUP} | cut -d: -f3)" ]; then
      addgroup -g "${GID}" "${GROUP}"
   elif [ ! "$(getent group "${GROUP}" | cut -d: -f3)" = "${GID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group GID mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${USER}" | cut -d: -f3)" ]; then
      adduser -s /bin/ash -D -G "${GROUP}" -u "${UID}" "${USER}" -h "/home/$USER"
   elif [ ! "$(getent passwd "${USER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User UID mismatch - exiting"
      exit 1
   fi
}

if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User name invalid - exiting" && exit 1; fi
if [ -z "${APPLEID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID invalid - exiting" && exit 1; fi
if [ -z "${APPLEPASSWORD}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple Password not specified - exiting" && exit 1; fi
if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group name invalid - exiting" && exit 1; fi
if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Group ID invalid - exiting" && exit 1; fi
if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User name invalid - exiting" && exit 1; fi
if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    User ID invalid - exiting" && exit 1; fi

if [ "${GENERATECOOKIE}" = "True" ]; then
   CreateGroup
   CreateUser
   if [ -f "${CONFIGDIR}/${COOKIE}" ]; then rm "${CONFIGDIR}/${COOKIE}"; fi
   su "${USER}" -c "/usr/bin/icloudpd --username \"${APPLEID}\" --password \"${APPLEPASSWORD}\" --cookie-directory \"${CONFIGDIR}\""
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie generated. Sync should now be successful"
   exit 0
fi

CheckCookie

if [ ! -f "/home/${USER}/iCloud/.mounted" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    iCloud folder not mounted - exiting" && exit 1; fi
if [ -z "${INTERVAL}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Sync interval not specified - exiting" && exit 1; fi

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
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation started for ${USER}"
   if [ -f "/home/${USER}/iCloud/.mounted" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Sync ${USER} iCloud..."
      su -s /bin/ash "${USER}" -c "/usr/bin/icloudpd --directory /home/${USER}/iCloud --cookie-directory \"${CONFIGDIR}\" --username \"${APPLEID}\" --password \"${APPLEPASSWORD}\" \""${CLIOPTIONS}"\""
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
      EXPIREWEB="${EXPIREWEB::-1}"
      EXPIREWEB="${EXPIREWEB/ / @ }"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Web page cookie expires: ${EXPIREWEB}"
      EXPIRE2FA="${EXPIRE2FA::-1}"
      EXPIRE2FASECS="$(date -d "${EXPIRE2FA}" '+%s')"
      DAYSREMAINING="$(expr $((EXPIRE2FASECS - $(date '+%s'))) / 86400)"
      EXPIRE2FA="${EXPIRE2FA/ / @ }"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie expires: ${EXPIRE2FA}"
      if [ "${DAYSREMAINING}" -lt 7 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Only ${DAYSREMAINING} days until two factor authentication cookie expires - Please reinitialise"
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation complete for ${USER}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Next syncronisation at $(date +%H:%M -d "${INTERVAL} seconds")"
      sleep "${INTERVAL}"
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Underlying volume is not mounted. Waiting a minute before retrying"
      sleep 60
   fi
done
