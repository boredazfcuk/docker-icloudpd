#!/bin/ash

EXPIRED=0
ICLOUDPD=$(cat /tmp/EXIT_CODE)
COOKIEDIR=/cookie

if [ -z "${AUTHTYPE}" ] || [ "${AUTHTYPE}" = "2FA" ]; then
   COOKIE="$(echo -n ${APPLEID//[^a-zA-Z0-9]/} | tr '[:upper:]' '[:lower:]')"
   EXPIRE2FA="$(grep "X-APPLE-WEBAUTH-HSA-TRUST" "${COOKIEDIR}/${COOKIE}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   EXPIRE2FASECS="$(date -d "${EXPIRE2FA}" '+%s')"
   DAYSREMAINING="$(($((EXPIRE2FASECS - $(date '+%s'))) / 86400))"
   if [ -z "${NOTIFICATIONDAYS}" ]; then NOTIFICATIONDAYS=7; fi
   if [ "${DAYSREMAINING}" -lt "${NOTIFICATIONDAYS}" ]; then EXPIRED=1; fi
fi

if [ $(( ICLOUDPD + EXPIRED )) -ne 0 ]; then exit 1; fi
