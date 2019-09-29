FROM alpine:latest
MAINTAINER boredazfcuk

ENV CONFIGDIR="/config" \
   REQUIREMENTS="python3 py-pip exiftool coreutils tzdata curl" \
   BUILDDEPENDENCIES="git gcc python3-dev musl-dev libffi-dev openssl-dev" \
   PYTHONDEPENDENCIES="docopt piexif click==6.0 certifi pytz tzlocal six chardet idna urllib3 requests future keyrings.alt==1.0 keyring==8.0 pyicloud-ipd tqdm schema python-dateutil" \
   REPO="ndbroadbent/icloud_photos_downloader"

COPY sync-icloud.sh /usr/local/bin/sync-icloud.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
   apk add --no-cache --no-progress --virtual=build-deps ${BUILDDEPENDENCIES} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${REQUIREMENTS} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip  && \
   pip3 install ${PYTHONDEPENDENCIES} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${REPO}" && \
   TEMP=$(mktemp -d) && \
   git clone -b master "https://github.com/${REPO}.git" "${TEMP}" && \
   cd "${TEMP}" && \
   python3 setup.py install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on startup script, clean up and exit" && \
   chmod +x /usr/local/bin/sync-icloud.sh /usr/local/bin/healthcheck.sh && \
   rm -r "${TEMP}" && \
   apk del --no-progress --purge build-deps

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${CONFIGDIR}"

CMD /usr/local/bin/sync-icloud.sh