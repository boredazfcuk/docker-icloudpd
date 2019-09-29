#!/bin/ash

##### Base Command ####
ICLOUDPD="/usr/bin/icloudpd --username=${APPLEID} --password=${APPLEPASSWORD} --cookie-directory=/config --directory=/data --no-progress-bar ${CLIOPTIONS}"

##### Functions #####
CheckTerminal(){
   if [ -t 0 ]; then
      INTERACTIVE=True
   else
      INTERACTIVE=False
   fi
}

CheckVariables(){
   if [ -z "${INTERVAL}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Syncronisation interval not set, defaulting to 86400 seconds (1 day) "; INTERVAL="86400"; fi
   if [ -z "${TZ}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Time zone not set, defaulting to 'Europe/Stockholm'"; export TZ="Europe/Stockholm"; fi
   if [ -z "${AUTHTYPE}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Authentication type not set, defaulting to two factor authentication"; AUTHTYPE="2FA"; fi
   if [ -z "${APPLEPASSWORD}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID Password not set - exiting"; exit 1; fi
   if [ -z "${APPLEID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Apple ID not set - exiting"; exit 1; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Running as: $(id)"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID: ${APPLEID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Apple ID Password: ${APPLEPASSWORD}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Cookie path: /config/${COOKIE}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Command line options: ${CLIOPTIONS}"
}

Generate2FACookie(){
   if [ -f "/config/${COOKIE}" ]; then
      rm "/config/${COOKIE}"
   fi
   echo "${ICLOUDPD}"
   ${ICLOUDPD}
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie generated. Sync should now be successful"
   exit 0
}

Check2FACookie(){
   if [ -f "/config/${COOKIE}" ]; then
      if [ $(grep -c "X-APPLE-WEBAUTH-HSA-TRUST" "/config/${COOKIE}") -eq 1 ]; then
         EXPIRE2FA="$(grep "X-APPLE-WEBAUTH-HSA-TRUST" "/config/${COOKIE}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
         EXPIRE2FASECS="$(date -d "${EXPIRE2FA}" '+%s')"
         DAYSREMAINING="$(($((EXPIRE2FASECS - $(date '+%s'))) / 86400))"
         echo "${DAYSREMAINING}" > "/config/DAYS_REMAINING"
         if [ "${DAYSREMAINING}" -gt 0 ]; then COOKIE2FAVALID="True"; fi
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Valid two factor authentication cookie found. Days until expiration: ${DAYSREMAINING}"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie is not 2FA capable, authentication type may have changed. Please run container interactively to generate - Retry in 5 minutes"
         sleep 300
      fi
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Cookie does not exist. Please run container interactively to generate - Retry in 5 minutes"
      sleep 300
   fi
}

SetDateTimeFromExif(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Set correct file time stamp from exif data..."
   exiftool -d "%Y:%m:%d %H:%M:%S" '-FileModifyDate<createdate' '-FileModifyDate<creationdate' '-filemodifydate<datetimeoriginal' -if '(($datetimeoriginal and ($datetimeoriginal ne $filemodifydate)) or ($creationdate and ($creationdate ne $filemodifydate)))' -r -q "/data"
}

Display2FAExpiry(){
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Two factor authentication cookie expires: ${EXPIRE2FA/ / @ }"
      if [ "${DAYSREMAINING}" -lt "${NOTIFICATIONDAYS}" ]; then
         if [ "${SYNCTIME}" -gt "${NEXTNOTIFICATION}" ]; then
            if [ "${DAYSREMAINING}" -eq 1 ]; then
               echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Final day before two factor authentication cookie expires - Please reinitialise now"
            else
               echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING  Only ${DAYSREMAINING} days until two factor authentication cookie expires - Please reinitialise"
            fi
         fi
      fi
}

SyncUser(){
   while :; do
      if [ "${AUTHTYPE}" = "2FA" ]; then
         COOKIE2FAVALID=False
         while [ "${COOKIE2FAVALID}" = "False" ]; do Check2FACookie; done
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Download started"
      SYNCTIME="$(date +%s -d '+15 minutes')"

      echo "${ICLOUDPD}"
      ${ICLOUDPD}

      EXITCODE=$?
      echo "${EXITCODE}" > /tmp/EXIT_CODE
      if [ "${EXITCODE}" -ne 0 ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR    Error during download - Exit code: ${EXITCODE}"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Download successful"
      fi
      if [ "${SETDATETIMEEXIF}" = "True" ]; then SetDateTimeFromExif; fi
      if [ "${AUTHTYPE}" = "2FA" ]; then Display2FAExpiry; fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Syncronisation complete"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     Next syncronisation at $(date +%H:%M -d "${INTERVAL} seconds")"
      sleep "${INTERVAL}"
   done
}

##### Script #####
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO     ***** iCloudPhotoDownloader container started *****"
COOKIE="$(echo -n ${APPLEID//[^a-zA-Z0-9]/} | tr '[:upper:]' '[:lower:]')"
CheckTerminal
CheckVariables
if [ "${INTERACTIVE}" = "True" ]; then Generate2FACookie; fi
SyncUser
