FROM alpine:3.13.5
MAINTAINER boredazfcuk

ENV config_dir="/config"

# Container version serves no real purpose. Increment to force a container rebuild.
ARG container_version="1.0.13"
ARG app_dependencies="python3 py3-pip exiftool coreutils tzdata curl libheif-tools py3-certifi py3-cffi py3-cryptography py3-secretstorage py3-jeepney py3-dateutil"
ARG build_dependencies="git"
ARG python_dependencies="pytz tzlocal wheel"
ARG app_repo="ndbroadbent/icloud_photos_downloader"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR ICLOUDPD ${container_version} *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
  apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clone ${app_repo}" && \
   temp_dir=$(mktemp -d) && \
   git clone -b master "https://github.com/${app_repo}.git" "${temp_dir}" && \
   cd "${temp_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --no-cache-dir ${python_dependencies} && \
   pip3 install --no-cache-dir -r requirements.txt && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   python3 setup.py install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   cd / && \
   rm -r "${temp_dir}" && \
   apk del --no-progress --purge build-deps

COPY sync-icloud.sh /usr/local/bin/sync-icloud.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on startup script and healthcheck" && \
   chmod +x /usr/local/bin/sync-icloud.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/sync-icloud.sh
