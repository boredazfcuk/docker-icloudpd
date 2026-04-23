# syntax=docker/dockerfile:1

# Stage 1 — compile
FROM alpine:latest AS builder

ARG icloudpd_branch="master"

RUN apk add --no-progress --no-cache gcc python3-dev py3-pip libc-dev libffi-dev cargo openssl-dev git

RUN git clone --depth 1 --branch "${icloudpd_branch}" https://github.com/icloud-photos-downloader/icloud_photos_downloader.git /src/icloudpd

# Apply PR-#1325
WORKDIR /src/icloudpd
RUN git config --global user.email "docker-build@localhost" && \
    git config --global user.name "Docker Build" && \
    git fetch origin pull/1325/head:pr-1325 && \
    git cherry-pick pr-1325

# Build a wheel into /dist so the final stage can install it
RUN python3 -m venv /build-venv && \
    /build-venv/bin/pip install --upgrade pip build && \
    /build-venv/bin/python -m build --wheel --outdir /dist .

# Stage 2 — build image
FROM alpine:latest

LABEL maintainer="boredazfcuk"

ENV XDG_DATA_HOME="/config" \
    TZ="UTC" \
    ENV="/etc/profile" \
    config_file="/config/icloudpd.conf"

# Runtime dependencies only
ARG app_dependencies="findutils nano nano-syntax py3-pip exiftool coreutils \
    tzdata curl libheif imagemagick shadow jq jpeg bind-tools expect \
    inotify-tools msmtp python3"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** Build started for boredazfcuk's docker-icloudpd *****" && \
    echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install runtime dependencies" && \
    apk add --no-progress --no-cache ${app_dependencies} && \
    find /usr/share/nano -name '*.nanorc' -printf "include %p\n" >>/etc/nanorc

# Copy the wheel built in stage 1 and install it into a clean venv
COPY --from=builder /dist/*.whl /tmp/wheels/

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install iCloudPD from pre-built wheel (with PR-1325 patch)" && \
    python3 -m venv /opt/icloudpd && \
    /opt/icloudpd/bin/pip install --upgrade pip && \
    /opt/icloudpd/bin/pip install --no-cache-dir /tmp/wheels/*.whl && \
    rm -rf /tmp/wheels

COPY build_version.txt /opt
COPY --chmod=0755 *.sh /usr/local/bin/
COPY authenticate.exp /opt/authenticate.exp
COPY CONFIGURATION.md /opt
COPY profile /etc/profile

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
    CMD /usr/local/bin/healthcheck.sh

VOLUME /config
CMD ["/usr/local/bin/launcher.sh"]