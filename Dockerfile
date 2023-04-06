FROM alpine:3.17.3
MAINTAINER boredazfcuk

ENV config_dir="/config" TZ="UTC"

ARG build_dependencies="git"
ARG app_dependencies="python3 py3-pip exiftool coreutils tzdata curl py3-certifi py3-cffi py3-cryptography py3-secretstorage py3-jeepney py3-dateutil imagemagick shadow"
ARG python_dependencies="pytz wheel"
ARG python_fix_dependencies="pyicloud"
ARG app_repo="icloud-photos-downloader/icloud_photos_downloader"
ARG fix_repo="boredazfcuk/icloud_photos_downloader"
ARG app_dir="/opt/icloudpd"
ARG app_fix_dir="/opt/china_auth_fix"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR ICLOUDPD *****" && \
   mkdir --parents "${app_dir}" "${app_fix_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
  apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clone ${app_repo}" && \
   git clone "https://github.com/${app_repo}.git" "${app_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clone ${fix_repo}" && \
   git clone -b china_auth_fix "https://github.com/${fix_repo}.git" "${app_fix_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir ${python_dependencies} && \
   pip3 install --no-cache-dir -r "${app_dir}/requirements.txt" && \
   pip3 install --no-cache-dir ${python_fix_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Apply Python 3.10 fixes" && \
   sed -i 's/from collections import Callable/from collections.abc import Callable/' \
      "$(pip3 show keyring | grep Location | awk '{print $2}')/keyring/util/properties.py" && \
   sed -i -e 's/password_encrypted = base64.decodestring(password_base64)/password_encrypted = base64.decodebytes(password_base64)/' \
      -e 's/password_base64 = base64.encodestring(password_encrypted).decode()/password_base64 = base64.encodebytes(password_encrypted).decode()/' \
      "$(pip3 show keyrings.alt | grep Location | awk '{print $2}')/keyrings/alt/file_base.py" && \
   sed -i \
      -e "s#apple.com/#apple.com.cn/#" \
      -e "s#icloud.com/#icloud.com.cn/#" \
      -e "s#icloud.com\"#icloud.com.cn\"#" \
      "$(pip3 show pyicloud | grep Location | awk '{print $2}')/pyicloud/base.py" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Make indexing error more accurate" && \
   sed -i 's/again in a few minutes/again later. This process may take a day or two./' \
   "$(pip3 show pyicloud | grep Location | awk '{print $2}')/pyicloud/services/photos.py" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   apk del --no-progress --purge build-deps

COPY build_version.txt /
COPY --chmod=0755 *.sh /usr/local/bin/

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/sync-icloud.sh
