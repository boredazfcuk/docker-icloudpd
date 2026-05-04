# syntax=docker/dockerfile:1

# =============================================================================
# Stage 1 — builder
# =============================================================================
FROM alpine:latest AS builder

ARG icloudpd_branch="master"

# Build-time dependencies only — gone after this stage
RUN apk add --no-progress --no-cache \
      gcc python3-dev py3-pip libc-dev libffi-dev cargo openssl-dev git

# Clone upstream at the requested branch/tag
RUN git clone --depth 1 --branch "${icloudpd_branch}" \
      https://github.com/icloud-photos-downloader/icloud_photos_downloader.git \
      /src/icloudpd

# Apply PR-1335 (push notification trigger + SMS trustedPhoneNumbers parsing fix)
WORKDIR /src/icloudpd
RUN git config --global user.email "docker-build@localhost" && \
    git config --global user.name "Docker Build" && \
    git fetch origin pull/1335/head:pr-1335 && \
    git cherry-pick pr-1335

# Install directly into the venv that will be copied to the final stage.
RUN python3 -m venv /opt/icloudpd && \
    /opt/icloudpd/bin/pip install --upgrade pip && \
    /opt/icloudpd/bin/pip install --no-cache-dir .


# =============================================================================
# Stage 2 — final image
# =============================================================================
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

# Copy the fully-compiled venv from the builder stage — no recompilation needed
COPY --from=builder /opt/icloudpd /opt/icloudpd

# Symlink the venv binaries so scripts can call icloudpd / icloud directly
RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Link iCloudPD binaries (with PR-1335 patch)" && \
    ln -sf /opt/icloudpd/bin/icloudpd /usr/local/bin/icloudpd && \
    ln -sf /opt/icloudpd/bin/icloud    /usr/local/bin/icloud

COPY build_version.txt /opt
COPY --chmod=0755 *.sh /usr/local/bin/
COPY authenticate.exp  /opt/authenticate.exp
COPY CONFIGURATION.md  /opt
COPY profile           /etc/profile

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
    CMD /usr/local/bin/healthcheck.sh

VOLUME /config
CMD ["/usr/local/bin/launcher.sh"]