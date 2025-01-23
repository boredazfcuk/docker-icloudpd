FROM alpine:latest
LABEL maintainer="boredazfcuk"

ENV XDG_DATA_HOME="/config" TZ="UTC" ENV="/etc/profile" config_file="/config/icloudpd.conf"

ARG icloudpd_version="1.26.1"
ARG build_dependencies="gcc python3-dev libc-dev libffi-dev cargo openssl-dev"
ARG app_dependencies="findutils nano nano-syntax py3-pip exiftool coreutils tzdata curl libheif imagemagick shadow jq jpeg bind-tools expect inotify-tools msmtp"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** Build started for boredazfcuk's docker-icloudpd *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache --virtual build ${build_dependencies} && \
   apk add --no-progress --no-cache ${app_dependencies} && \
   find /usr/share/nano -name '*.nanorc' -printf "include %p\n" >>/etc/nanorc && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install iCloudPD latest release" && \
   python -m venv /opt/icloudpd && \
   source /opt/icloudpd/bin/activate && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir icloudpd && \
   deactivate && \
   apk del build

COPY build_version.txt /opt
COPY --chmod=0755 *.sh /usr/local/bin/
COPY authenticate.exp /opt/authenticate.exp
COPY CONFIGURATION.md /opt
COPY profile /etc/profile

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh
  
VOLUME "/config"

CMD /usr/local/bin/launcher.sh