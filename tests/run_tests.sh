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

printf '\n%s test(s), %s failure(s)\n' "${tests_run}" "${tests_failed}"
[ "${tests_failed}" -eq 0 ]
