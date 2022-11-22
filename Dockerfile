# Fix base to Alpine 3.16.1 due to:-
# Alpine 3.14 & 3.15 - Python 3.9 incompatibility introduced: AttributeError: module 'base64' has no attribute 'decodestring'
# Alpine 3.16        - Python 3.10 incompatibility introduced: ImportError: cannot import name 'Callable' from 'collections' (/usr/lib/python3.10/collections/__init__.py)
FROM alpine:3.16.3
MAINTAINER boredazfcuk

ENV config_dir="/config" \
   TZ="UTC"

# Container version serves no real purpose. Increment to force a container rebuild.
ARG container_version="1.0.21"
ARG app_dependencies="python3 py3-pip exiftool coreutils tzdata curl py3-certifi py3-cffi py3-cryptography py3-secretstorage py3-jeepney py3-dateutil imagemagick shadow"
ARG build_dependencies="git"
# Fix tzlocal to 2.1 due to Python 3.8 being default in alpine 3.13.5+
ARG python_dependencies="pytz tzlocal==2.1 wheel"
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
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install iOS 16 Shared Libraries patch" && \
   curl https://patch-diff.githubusercontent.com/raw/icloud-photos-downloader/icloud_photos_downloader/pull/489.patch | git apply && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir ${python_dependencies} && \
   pip3 install --no-cache-dir -r requirements.txt && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install iOS 16 Shared Librares pyicloud_ipd patch" && \
   cd /usr/lib/python3.10/site-packages && \
   mv pyicloud_ipd pyicloud && \
   curl https://patch-diff.githubusercontent.com/raw/icloud-photos-downloader/pyicloud/pull/8.patch | git apply && \
   mv pyicloud pyicloud_ipd && \
   cd - && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   python3 setup.py install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Apply Python 3.10 fixes" && \
   sed -i 's/from collections import Callable/from collections.abc import Callable/' "/usr/lib/python3.10/site-packages/keyring/util/properties.py" && \
   sed -i -e 's/password_encrypted = base64.decodestring(password_base64)/password_encrypted = base64.decodebytes(password_base64)/' \
      -e 's/password_base64 = base64.encodestring(password_encrypted).decode()/password_base64 = base64.encodebytes(password_encrypted).decode()/' \
      "/usr/lib/python3.10/site-packages/keyrings/alt/file_base.py" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Make indexing error more accurate" && \
   sed -i 's/again in a few minutes/again later. This process may take hours./' "/usr/lib/python3.10/site-packages/pyicloud_ipd/services/photos.py" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   cd / && \
   rm -r "${app_temp_dir}" && \
   apk del --no-progress --purge build-deps

COPY --chmod=0755 sync-icloud.sh /usr/local/bin/sync-icloud.sh
COPY --chmod=0755 healthcheck.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/sync-icloud.sh
