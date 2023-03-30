FROM alpine:3.17.2
MAINTAINER boredazfcuk

ENV config_dir="/config" \
   TZ="UTC"

# Container/icloudpd versions serve no real purpose. Increment to force a container rebuild.
ARG build_version=127
ARG icloudpd_version=1.12.0
ARG app_dependencies="python3 py3-pip exiftool coreutils tzdata curl py3-certifi py3-cffi py3-cryptography py3-secretstorage py3-jeepney py3-dateutil imagemagick shadow"
ARG python_dependencies="pytz tzlocal==2.1 wheel"
ARG build_dependencies="git"
ARG app_repo="icloud-photos-downloader/icloud_photos_downloader"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR ICLOUDPD ${container_version} *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
  apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clone ${app_repo}" && \
   app_temp_dir=$(mktemp -d) && \
   git clone -b master "https://github.com/${app_repo}.git" "${app_temp_dir}" && \
   cd "${app_temp_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Apply pull request" && \
   git fetch origin pull/608/head:domain_fix && \
   git checkout domain_fix && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip && \
   pip3 install -U setuptools && \
   pip3 install --no-cache-dir ${python_dependencies} && \
   pip3 install --no-cache-dir -r requirements.txt -r requirements-pip.txt && \
   sed -i '/install_requires/d' setup.py && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   python3 setup.py install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Make indexing error more accurate" && \
   sed -i 's/again in a few minutes/again later. This process may take a day or two./' "/usr/lib/python3.10/site-packages/pyicloud/services/photos.py" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   cd / && \
   rm -r "${app_temp_dir}" && \
   apk del --no-progress --purge build-deps

COPY --chmod=0755 sync-icloud.sh /usr/local/bin/sync-icloud.sh
COPY --chmod=0755 healthcheck.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/sync-icloud.sh
