#!/bin/sh
# Unit tests for the re-authentication functions in sync-icloud.sh.
# Run from the repository root: sh tests/run_tests.sh
# Requires GNU/busybox date. On macOS, run it in the image instead:
#   docker run --rm -v "$PWD:/src" -w /src alpine:latest sh tests/run_tests.sh

script_under_test="./sync-icloud.sh"
tests_run=0
tests_failed=0

# Echo a single function's source. Relies on the file's convention of a bare
# "name()" line and a closing brace in column 1.
extract_function()
{
   awk -v fn="${1}()" '
      $0 == fn { capture = 1 }
      capture { print }
      capture && $0 == "}" { exit }
   ' "${script_under_test}"
}

assert_equals()
{
   tests_run=$((tests_run + 1))
   if [ "${2}" = "${3}" ]
   then
      printf 'ok   %s\n' "${1}"
   else
      tests_failed=$((tests_failed + 1))
      printf 'FAIL %s\n     expected: %s\n     actual:   %s\n' "${1}" "${3}" "${2}"
   fi
}

##### reauth_instructions #####

eval "$(extract_function reauth_instructions)"

(
   notification_type="telegram"; telegram_polling="true"; user="Josh"; icloud_china="false"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: telegram polling names the reply" \
   "$(cat /tmp/icloudpd_test_out)" \
   "To re-authenticate now, reply to this chat with: Josh auth"

(
   notification_type="telegram"; telegram_polling="false"; user="Josh"; icloud_china="false"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: telegram without polling gives the exec command" \
   "$(cat /tmp/icloudpd_test_out)" \
   "To re-authenticate now, run: docker exec -it <container name> reauth.sh"

(
   notification_type="pushover"; telegram_polling="true"; user="Josh"; icloud_china="false"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: non-telegram gives the exec command" \
   "$(cat /tmp/icloudpd_test_out)" \
   "To re-authenticate now, run: docker exec -it <container name> reauth.sh"

(
   notification_type="telegram"; telegram_polling="true"; user="Josh"; icloud_china="true"
   printf '%s' "$(reauth_instructions)"
) > /tmp/icloudpd_test_out
assert_equals "reauth_instructions: china variant names the reply" \
   "$(cat /tmp/icloudpd_test_out)" \
   "如需立即重新验证，请在此对话中回复：Josh auth"

rm -f /tmp/icloudpd_test_out

##### require_reauthentication / clear_reauthentication_hold #####

eval "$(extract_function require_reauthentication)"
eval "$(extract_function clear_reauthentication_hold)"

log_error() { :; }
log_info() { :; }
log_debug() { :; }
send_notification() { echo "notified:${1}" >> "${notifications_sent}"; }

reauth_marker_file="/tmp/icloudpd_test_marker"
notifications_sent="/tmp/icloudpd_test_notifications"
rm -f "${reauth_marker_file}" "${notifications_sent}"
: > "${notifications_sent}"

# The default path must survive: an earlier version assigned it inside a
# command substitution, so the assignment was lost in the subshell.
(
   unset reauth_marker_file
   require_reauthentication "Default path check" >/dev/null 2>&1
   printf '%s' "${reauth_marker_file}"
) > /tmp/icloudpd_test_default
assert_equals "require_reauthentication: defaults the marker path in this shell" \
   "$(cat /tmp/icloudpd_test_default)" \
   "/tmp/icloudpd/awaiting_reauthentication"
rm -f /tmp/icloudpd_test_default /tmp/icloudpd/awaiting_reauthentication

require_reauthentication "Cookie expired at: yesterday"
assert_equals "require_reauthentication: writes the marker" \
   "$(cat "${reauth_marker_file}")" \
   "Cookie expired at: yesterday"
assert_equals "require_reauthentication: sets the state variable" \
   "${authentication_required}" \
   "Cookie expired at: yesterday"

require_reauthentication "Cookie expired at: yesterday"
assert_equals "require_reauthentication: is idempotent" \
   "$(wc -l < "${reauth_marker_file}" | tr -d ' ')" \
   "1"

clear_reauthentication_hold
assert_equals "clear_reauthentication_hold: removes the marker" \
   "$([ -f "${reauth_marker_file}" ] && echo present || echo absent)" \
   "absent"
assert_equals "clear_reauthentication_hold: clears the state variable" \
   "${authentication_required:-empty}" \
   "empty"
assert_equals "clear_reauthentication_hold: notifies once on recovery" \
   "$(cat "${notifications_sent}")" \
   "notified:startup"

: > "${notifications_sent}"
clear_reauthentication_hold
assert_equals "clear_reauthentication_hold: silent when not holding" \
   "$(cat "${notifications_sent}")" \
   ""

rm -f "${reauth_marker_file}" "${notifications_sent}"

##### reauthentication_reminder #####

eval "$(extract_function reauthentication_reminder)"

log_warning() { :; }
send_notification() { printf '%s|%s\n' "${1}" "${4}" >> "${notifications_sent}"; }

notifications_sent="/tmp/icloudpd_test_notifications"
: > "${notifications_sent}"
apple_id="someone@example.com"
icloud_china="false"
notification_type="telegram"
telegram_polling="true"
user="Josh"
download_interval=86400
unset reauth_notification_interval next_reauth_notification_time
authentication_required="Cookie expired at: yesterday"

reauthentication_reminder
assert_equals "reauthentication_reminder: sends on the first pass" \
   "$(wc -l < "${notifications_sent}" | tr -d ' ')" \
   "1"
assert_equals "reauthentication_reminder: classified as cookie expired" \
   "$(cut -d'|' -f1 < "${notifications_sent}")" \
   "cookie expired"
assert_equals "reauthentication_reminder: message carries reason and instructions" \
   "$(cut -d'|' -f2 < "${notifications_sent}")" \
   "Authentication required for Apple ID: someone@example.com - Cookie expired at: yesterday. Downloads are paused until this is resolved. To re-authenticate now, reply to this chat with: Josh auth"

reauthentication_reminder
assert_equals "reauthentication_reminder: throttled on the next pass" \
   "$(wc -l < "${notifications_sent}" | tr -d ' ')" \
   "1"

next_reauth_notification_time=1
reauthentication_reminder
assert_equals "reauthentication_reminder: sends again once the interval has passed" \
   "$(wc -l < "${notifications_sent}" | tr -d ' ')" \
   "2"

reauth_notification_interval=3600
next_reauth_notification_time=1
reauthentication_reminder
assert_equals "reauthentication_reminder: override sets the next time an hour out" \
   "$(( next_reauth_notification_time - $(date +%s) > 3500 && next_reauth_notification_time - $(date +%s) <= 3600 ))" \
   "1"

rm -f "${notifications_sent}"

##### download exit code and completion check #####

# download_photos runs the real binary path, so stand a fake iCloudPD in its place. It prints
# FAKE_OUTPUT to stdout and exits with FAKE_EXIT, like the release binary does.
# Needs root (run_as uses su), which the docker run in the header gives you.
eval "$(extract_function run_as)"
eval "$(extract_function sync_log_next_line)"
eval "$(extract_function flag_incomplete_download)"
eval "$(extract_function download_photos)"
log_debug() { :; }
user="root"; command_line=""; log_level="info"; skip_download="false"
mkdir -p /tmp/icloudpd /opt/icloudpd/bin
printf '#!/bin/ash\nprintf "%%b\\n" "${FAKE_OUTPUT}"\nexit "${FAKE_EXIT}"\n' > /opt/icloudpd/bin/icloudpd
chmod 755 /opt/icloudpd/bin/icloudpd
completed="2026-10-12 16:02:40 INFO     All photos and videos have been downloaded"
not_indexed="2026-10-14 15:39:59 INFO     Apple iCloud Photo Library has not finished indexing yet"

export FAKE_OUTPUT="${completed}" FAKE_EXIT=0
download_photos >/dev/null
assert_equals "download_photos: finished run is a success" \
   "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" "0"
assert_equals "download_photos: finished run leaves no error" \
   "$(wc -c < /tmp/icloudpd/icloudpd_download_error | tr -d ' ')" "0"

export FAKE_OUTPUT="${completed}" FAKE_EXIT=1
download_photos >/dev/null
assert_equals "download_photos: records iCloudPD's own exit code" \
   "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" "1"

export FAKE_OUTPUT="${not_indexed}" FAKE_EXIT=0
download_photos >/dev/null
assert_equals "download_photos: exit 0 without the completion message is a failure" \
   "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" "1"
assert_equals "download_photos: failure names the last message" \
   "$(cat /tmp/icloudpd/icloudpd_download_error)" \
   "iCloudPD exited without finishing the download. Last message: ${not_indexed}"

export FAKE_OUTPUT="2026-10-12 16:02:40 INFO     All photos have been downloaded" FAKE_EXIT=0
download_photos >/dev/null
assert_equals "download_photos: skip_videos wording counts as finished" \
   "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" "0"

# Libraries and albums append every run to one sync log, so an earlier run's completion message
# must not count for a later run.
printf '%s\n' "${completed}" > /tmp/icloudpd/icloudpd_sync.log
sync_log_start="$(sync_log_next_line)"
printf '%s\n' "${not_indexed}" >> /tmp/icloudpd/icloudpd_sync.log
echo 0 > /tmp/icloudpd/icloudpd_download_exit_code
> /tmp/icloudpd/icloudpd_download_error
flag_incomplete_download "${sync_log_start}"
assert_equals "flag_incomplete_download: only looks at this run's output" \
   "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" "1"

skip_download="true"
download_photos >/dev/null
assert_equals "download_photos: skip_download is not flagged" \
   "$(cat /tmp/icloudpd/icloudpd_download_exit_code)" "0"

unset FAKE_OUTPUT FAKE_EXIT
rm -f /opt/icloudpd/bin/icloudpd /tmp/icloudpd/icloudpd_sync.log /tmp/icloudpd/icloudpd_download_exit_code /tmp/icloudpd/icloudpd_download_error

printf '\n%s test(s), %s failure(s)\n' "${tests_run}" "${tests_failed}"
[ "${tests_failed}" -eq 0 ]
