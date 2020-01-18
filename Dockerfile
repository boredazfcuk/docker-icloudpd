FROM alpine:latest
MAINTAINER boredazfcuk
ARG app_dependencies="python3 py-pip exiftool coreutils tzdata curl"
ARG build_dependencies="git gcc python3-dev musl-dev libffi-dev openssl-dev"
ARG python_dependencies="docopt piexif click==6.0 certifi pytz tzlocal six chardet idna urllib3 requests future keyrings.alt==1.0 keyring==8.0 pyicloud-ipd tqdm schema python-dateutil"
ARG app_repo="ndbroadbent/icloud_photos_downloader"
ENV config_dir="/config"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
   apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip  && \
   pip3 install ${python_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   temp_dir=$(mktemp -d) && \
   git clone -b master "https://github.com/${app_repo}.git" "${temp_dir}" && \
   cd "${temp_dir}" && \
   python3 setup.py install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
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