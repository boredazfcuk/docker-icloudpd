FROM alpine:3.17.2
MAINTAINER boredazfcuk

ENV config_dir="/config" TZ="UTC"

ARG app_dependencies="python3 py3-pip exiftool coreutils tzdata curl py3-certifi py3-cffi py3-cryptography py3-secretstorage py3-jeepney py3-dateutil imagemagick shadow"
ARG build_dependencies="git"
ARG app_repo="icloud-photos-downloader/icloud_photos_downloader"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR ICLOUDPD $(cat ./build_version.txt)*****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
  apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clone ${app_repo}" && \
   app_temp_dir=$(mktemp -d) && \
   git clone "https://github.com/${app_repo}.git" "${app_temp_dir}" && \
   cd "${app_temp_dir}" && \
   git fetch origin pull/608/head:domain_fix && \  
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Apply domain fix pull request" && \
   git checkout domain_fix && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir ${python_dependencies} && \
   pip3 install --no-cache-dir -r requirements.txt && \
   sed -i '/install_requires/d' setup.py && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   pip3 install . && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Make indexing error more accurate" && \
   sed -i 's/again in a few minutes/again later. This process may take a day or two./' "$(find / -name photos.py)" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   cd / && \
   rm -r "${app_temp_dir}" && \
   apk del --no-progress --purge build-deps

COPY --chmod=0755 *.sh /usr/local/bin/

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/sync-icloud.sh
