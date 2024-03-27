#!/bin/ash
/opt/icloudpd_latest/bin/icloudpd --username $(grep apple_id /config/icloudpd.conf | awk -F= '{print $2}') --auth-only