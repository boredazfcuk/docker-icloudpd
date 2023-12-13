FROM alpine:3.18.3
MAINTAINER boredazfcuk

ENV config_dir="/config" XDG_DATA_HOME="/config" TZ="UTC"

ARG icloudpd_version="1.16.2"
ARG python_version="3.11"
ARG build_dependencies="git gcc python3-dev musl-dev rust cargo libffi-dev openssl-dev"
ARG app_dependencies="py3-pip exiftool coreutils tzdata curl imagemagick shadow jq"
ARG fix_repo="boredazfcuk/icloud_photos_downloader"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** Build started for boredazfcuk's docker-icloudpd *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
  apk add --no-progress --no-cache --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
echo "$(date '+%d/ %m/%Y - %H:%M:%S') | Create and enter icloudpd_v.1.7.2_china virtual environment" && \
   python -m venv /opt/icloudpd_v1.7.2_china && \
   source /opt/icloudpd_v1.7.2_china/bin/activate && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clone ${fix_repo}" && \
   fix_dir=$(mktemp -d) && \
   git clone --branch china_auth_fix --depth=1 "https://github.com/${fix_repo}.git" "${fix_dir}" && \
   cd "${fix_dir}" && \
   sed -i 's/version="1.7.2/version="1.7.2_china_auth_fix/' setup.py && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies for China fix" && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir -r requirements.txt && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install iCloudPD v1.7.2_china_auth_fix" && \
   python3 setup.py install && \
   cd .. && \
   rm -r "${fix_dir}" && \
   sed -i -e 's/icloud.com/icloud.com.cn/g' /opt/icloudpd_v1.7.2_china/lib/python${python_version}/site-packages/pyicloud/base.py && \
   sed -i -e 's/apple.com/apple.com.cn/g' /opt/icloudpd_v1.7.2_china/lib/python${python_version}/site-packages/pyicloud/base.py && \
   sed -i -e 's/password_encrypted = base64.decodestring(password_base64)/password_encrypted = base64.decodebytes(password_base64)/' \
      -e 's/password_base64 = base64.encodestring(password_encrypted).decode()/password_base64 = base64.encodebytes(password_encrypted).decode()/' \
      "/opt/icloudpd_v1.7.2_china/lib/python${python_version}/site-packages/keyrings/alt/file_base.py" && \
   sed -i 's/again in a few minutes/again later. This process may take a day or two./' \
      "/opt/icloudpd_v1.7.2_china/lib/python${python_version}/site-packages/pyicloud/services/photos.py" && \
   deactivate && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install iCloudPD latest release" && \
   python -m venv /opt/icloudpd_latest && \
   source /opt/icloudpd_latest/bin/activate && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir wheel && \
   pip3 install --no-cache-dir icloudpd && \
   sed -i -e 's/password_encrypted = base64.decodestring(password_base64)/password_encrypted = base64.decodebytes(password_base64)/' \
      -e 's/password_base64 = base64.encodestring(password_encrypted).decode()/password_base64 = base64.encodebytes(password_encrypted).decode()/' \
      "/opt/icloudpd_latest/lib/python${python_version}/site-packages/keyrings/alt/file_base.py" && \
   sed -i 's/again in a few minutes/again later. This process may take a day or two./' \
      "/opt/icloudpd_latest/lib/python${python_version}/site-packages/pyicloud_ipd/services/photos.py" && \
   deactivate && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   apk del --no-progress --purge build-deps && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Fix Auth" && \
   wget https://github.com/scaraebeus/icloud_photos_downloader/archive/refs/heads/auth_fix.zip && \
   unzip auth_fix.zip && \
   cp -r ./icloud_photos_downloader-auth_fix/src/* /opt/icloudpd_latest/lib/python3.11/site-packages/ && \
   rm -r ./auth_fix.zip && \
   rm -r ./icloud_photos_downloader-auth_fix
COPY build_version.txt /
COPY --chmod=0755 *.sh /usr/local/bin/
COPY CONFIGURATION.md /opt

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/sync-icloud.sh
