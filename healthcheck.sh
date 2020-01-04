#!/bin/ash
ICLOUDPD=$(cat /tmp/EXIT_CODE)
if [ "${ICLOUDPD}" != 0 ]; then
   echo "iCloud Photos Downloader Error: ${ICLOUDPD}"
   exit 1
fi
if [ ! -z "${AUTHTYPE}" ] && [ "${AUTHTYPE}" = "2FA" ]; then
   COOKIE="$(echo -n ${APPLEID//[^a-zA-Z0-9]/} | tr '[:upper:]' '[:lower:]')"
   EXPIRE2FA="$(grep "X-APPLE-WEBAUTH-HSA-TRUST" "${CONFIGDIR}/${COOKIE}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   EXPIRE2FASECS="$(date -d "${EXPIRE2FA}" '+%s')"
   DAYSREMAINING="$(($((EXPIRE2FASECS - $(date '+%s'))) / 86400))"
   if [ -z "${NOTIFICATIONDAYS}" ]; then NOTIFICATIONDAYS=7; fi
   if [ "${DAYSREMAINING}" -lt "${NOTIFICATIONDAYS}" ]; then
      echo "Error: Two-factor authentication cookie has expired"
      exit 1
   fi
elif [ ! -z "${AUTHTYPE}" ] && [ "${AUTHTYPE}" = "Web" ]; then
   COOKIE="$(echo -n ${APPLEID//[^a-zA-Z0-9]/} | tr '[:upper:]' '[:lower:]')"
   EXPIREWEB="$(grep "X_APPLE_WEB_KB" "${CONFIGDIR}/${COOKIE}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   EXPIREWEBSECS="$(date -d "${EXPIREWEB}" '+%s')"
   DAYSREMAINING="$(($((EXPIREWEBSECS - $(date '+%s'))) / 86400))"
fi
echo "iCloud Photos Downloader successful and ${AUTHTYPE} cookie valid for ${DAYSREMAINING} day(s)"
exit 0