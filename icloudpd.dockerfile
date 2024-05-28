FROM alpine:latest
MAINTAINER boredazfcuk

ENV config_dir="/config" XDG_DATA_HOME="/config" TZ="UTC" ENV="/etc/profile"

ARG icloudpd_version="1.18.0"
ARG app_dependencies="findutils nano nano-syntax py3-pip exiftool coreutils tzdata curl imagemagick shadow jq libheif jpeg bind-tools expect inotify-tools"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** Build started for boredazfcuk's docker-icloudpd *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install requirements" && \
   apk add --no-progress --no-cache ${app_dependencies} && \
   find /usr/share/nano -name '*.nanorc' -printf "include %p\n" >>/etc/nanorc && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install iCloudPD latest release" && \
   python -m venv /opt/icloudpd && \
   source /opt/icloudpd/bin/activate && \
   pip3 install --upgrade pip && \
   pip3 install --no-cache-dir wheel && \
   pip3 install --no-cache-dir icloudpd && \
   deactivate

COPY build_version.txt /opt
COPY --chmod=0755 *.sh /usr/local/bin/
COPY authenticate.exp /opt/authenticate.exp
COPY CONFIGURATION.md /opt
COPY profile /etc/profile

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh
  
VOLUME "${config_dir}"

CMD /usr/local/bin/launcher.sh
